require 'thread'
require "net/http"
require "uri"
require "base64"

module Errplane
  class Worker
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

          retry_count = 5
          begin
            http = Net::HTTP.new("api.errplane.com", "80")
            response = http.post(url, data)
            log :debug, "Response code: #{response.code}"
          rescue => e
            retry_count -= 1
            unless retry_count.zero?
              log :info, "POST failed, retrying."
              sleep 10
              retry
            end
            log :info, "Unable to POST after retrying, aborting!"
          end
        end
      end

      def spawn_threads()
        Errplane.configuration.queue_worker_threads.times do
          log :debug, "Spawning background worker thread."

          Thread.new do
            while true
              sleep Errplane.configuration.queue_worker_polling_interval
              check_background_queue
            end
          end

        end
      end

      def check_background_queue
        log :debug, "Checking background queue."

        data = []

        while !Errplane.queue.empty? && data.size < 200
          log :debug, "Found data in the queue."
          n = Errplane.queue.pop

          begin
            case n[:source]
            when "active_support"
              case n[:name].to_s
              when "process_action.action_controller"
                timediff = n[:finish] - n[:start]
                data << "controllers/#{n[:payload][:controller]}/#{n[:payload][:action]} #{(timediff*1000).ceil} #{n[:finish].utc.to_i}"
                data << "views #{n[:payload][:view_runtime].ceil} #{n[:finish].utc.to_i }"
                data << "db #{n[:payload][:db_runtime].ceil} #{n[:finish].utc.to_i }"
              end
            when "exception"
              Errplane.transmitter.deliver n[:data], n[:url]
            when "custom"
              line = "#{n[:name]} #{n[:value] || 1} #{n[:timestamp]}"
              # adding the message in this way to ensure that the space between the timestamp and the base64 encoded part goes in.
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
