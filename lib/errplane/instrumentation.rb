require 'thread'
require "net/http"
require "uri"
require "base64"

module Errplane
  class Instrumentation
    class << self
      include Errplane::Logger

      def indent_lines(lines, num)
        lines.split("\n").map {|line| (" " * num) + line}.join("\n")
      end

      def post_data(data)
        if Errplane.configuration.ignore_current_environment?
          log :debug, "Current environment is ignored, skipping POST."
        else
          log :info, "Posting data:\n#{indent_lines(data, 13)}"
          url = "/api/v2/time_series/applications/#{Errplane.configuration.application_id}/environments/#{Errplane.configuration.rails_environment}?api_key=#{Errplane.configuration.api_key}"
          log :info, "Posting to: #{url}"

          retry_count = 5
          begin
            http = Net::HTTP.new("api.errplane.com", "80")
            response = http.post(url, data)
            log :info, "Response code: #{response.code}"
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

      def spawn_worker_threads()
        Errplane.configuration.queue_worker_threads.times do
          log :debug, "Spawning background worker thread."
          Thread.new do
            while true
              log :debug, "Checking background queue."
              sleep Errplane.configuration.queue_worker_polling_interval

              data = [].tap do |line|
                while !Errplane.queue.empty?
                  log :debug, "Found data in the queue."
                  n = Errplane.queue.pop

                  begin
                    case n[:source]
                    when "active_support"
                      case n[:name].to_s
                      when "process_action.action_controller"
                        timediff = n[:finish] - n[:start]
                        line << "controllers/#{n[:payload][:controller]}/#{n[:payload][:action]} #{(timediff*1000).ceil} #{n[:finish].utc.to_i}"
                        line << "views #{n[:payload][:view_runtime].ceil} #{n[:finish].utc.to_i }"
                        line << "db #{n[:payload][:db_runtime].ceil} #{n[:finish].utc.to_i }"
                      end
                    when "exception"
                      Errplane.transmitter.deliver n[:data], n[:url]
                    when "custom"
                      s = "#{n[:name]} #{n[:value] || 1} #{n[:timestamp]}"
                      s << " #{Base64.encode64(n[:message])}" if n[:message]
                      line << s
                    end
                  rescue => e
                    log :info, "Instrumentation Error! #{e.inspect}"
                  end
                end
              end

              post_data(data.join("\n")) unless data.empty?
            end
          end
        end
      end
    end
  end
end
