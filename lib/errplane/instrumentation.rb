require 'thread'
require "net/http"
require "uri"
require "base64"

module Errplane
  class Relay
    @@queue = Queue.new

    def self.queue
      return @@queue
    end

    def self.initialize
      @@queue = Queue.new
    end
  end

  class Instrumentation
    class << self
      include Errplane::Logger

      def post_data(data)
        log :info, "Posting data:\n#{data}"

        app_key = "app4you2love"
        env_key = "production"

        http = Net::HTTP.new("api1.errplane.com", "8086")
        response = http.post("/api/v2/time_series/applications/#{app_key}/environments/#{env_key}?api_key=ignored", data)
        log :info, "Response code: #{response.code}"
      end

      def spawn_thread()
        Thread.new do
          log :debug, "Spawning background thread."
          while true
            log :debug, "Checking background queue."
            sleep 5
            begin
              while !Errplane::Relay.queue.empty?
                log :info, "Found data in the queue."
                n = Errplane::Relay.queue.pop
                timediff = n[:finish] - n[:start]
                if( n[:name].to_s == "process_action.action_controller" )
                  data = [].tap do |line|
                    line << "controllers/#{n[:payload][:controller]}/#{n[:payload][:action]} #{(timediff*1000).ceil} #{n[:finish].utc.to_i}"
                    line << "views #{n[:payload][:view_runtime].ceil} #{n[:finish].utc.to_i }"
                    line << "db #{n[:payload][:db_runtime].ceil} #{n[:finish].utc.to_i }"
                  end
                  post_data(data.join("\n"))
                else
                  log :info, "Ignored instrumentation: #{n[:name]}"
                end
              end
            rescue => e
              log :info, "Instrumentation Error! #{e.inspect}"
            end
          end
        end
      end
    end
  end

  if defined?(ActiveSupport::Notifications)
    ActiveSupport::Notifications.subscribe do |name, start, finish, id, payload|
      h = { :name => name, :start => start, :finish => finish, :nid => id, :payload => payload }
      Errplane::Relay.queue.push h
    end
  end

  if defined?(PhusionPassenger)
    PhusionPassenger.on_event(:starting_worker_process) do |forked|
      if forked
        Errplane::Relay.initialize
        Errplane::Instrumentation.spawn_thread()
      end
    end
  else
    Errplane::Relay.initialize
    Errplane::Instrumentation.spawn_thread()
  end
end
