require 'thread'
require "net/http"
require "uri"
require "base64"

module Errplane
  class Worker
    MAX_POST_LINES = 200
    POST_RETRIES = 5

    class << self
      include Errplane::Logger

      def indent_lines(lines, num)
        lines.split("\n").map {|line| (" " * num) + line}.join("\n")
      end

      def post_data(data)
        if Errplane.configuration.ignore_current_environment?
          log :debug, "Current environment is ignored, skipping POST."
        else
          log :debug, "Posting data:\n#{indent_lines(data, 13)}"
          url = "/api/v2/time_series/applications/#{Errplane.configuration.application_id}/environments/#{Errplane.configuration.rails_environment}?api_key=#{Errplane.configuration.api_key}"
          log :debug, "Posting to: #{url}"

          retry_count = POST_RETRIES
          begin
            # http = Net::HTTP.new(Errplane.configuration.api_host, Errplane.configuration.api_host_port)
            http = Net::HTTP.new(Errplane.configuration.api_host, 443)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            http.open_timeout = 3
            http.read_timeout = 3

            response = http.post(url, data)
            log :debug, "Response code: #{response.code}"
            log :debug, "Response: #{response.inspect}"
          rescue => e
            retry_count -= 1
            unless retry_count.zero?
              log :info, "POST failed, retrying."
              sleep 1
              retry
            end
            log :info, "Unable to POST after retrying, aborting!"
          end
        end
      end

      def current_threads()
        Thread.list.select {|t| t[:errplane]}
      end

      def current_thread_count()
        Thread.list.count {|t| t[:errplane]}
      end

      def spawn_threads()
        Errplane.configuration.queue_worker_threads.times do |thread_num|
          log :debug, "Spawning background worker thread #{thread_num}."

          Thread.new do
            Thread.current[:errplane] = true

            at_exit do
              log :debug, "Thread exiting, flushing queue."
              check_background_queue(thread_num) until Errplane.queue.empty?
            end

            while true
              sleep Errplane.configuration.queue_worker_polling_interval
              check_background_queue(thread_num)
            end
          end
        end
      end

      def check_background_queue(thread_num = 0)
        log :debug, "Checking background queue on thread #{thread_num} (#{current_threads.count} active)"

        data = []

        while data.size < MAX_POST_LINES && !Errplane.queue.empty?
          n = Errplane.queue.pop(true) rescue next;
          log :debug, "Found data in the queue! (#{n[:name]})"

          begin
            case n[:source]
            when "active_support"
              case n[:name].to_s
              when "process_action.action_controller"
                timestamp = n[:finish].utc.to_i
                controller_runtime = ((n[:finish] - n[:start])*1000).ceil
                view_runtime = (n[:payload][:view_runtime] || 0).ceil
                db_runtime = (n[:payload][:db_runtime] || 0).ceil

                data << "controllers/#{n[:payload][:controller]}/#{n[:payload][:action]} #{controller_runtime} #{timestamp}"
                data << "views #{view_runtime} #{timestamp}"
                data << "db #{db_runtime} #{timestamp}"
              end
            when "exception"
              Errplane.transmitter.deliver n[:data], n[:url]
            when "custom"
              line = "#{n[:name]} #{n[:value] || 1} #{n[:timestamp]}"
              line = "#{line} #{Base64.encode64(n[:message]).strip}" if n[:message]
              data << line
            end
          rescue => e
            log :info, "Instrumentation Error! #{e.inspect}"
          end
        end

        post_data(data.join("\n")) unless data.empty?
      end
    end
  end
end
