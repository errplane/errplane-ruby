require 'thread'
require "net/http"
require "uri"
require "base64"

module Errplane
  class NotificationsQueue
    @@notifications = Queue.new

    def self.notifications
      return @@notifications
    end

    def self.initialize
      @@notifications = Queue.new
    end
  end

  PLOGGER = [] #Logger.new("log/perfs.log", shift_age = 7, shift_size = 5048576)

  def post_data(data)
    PLOGGER << "Posting data!\n -#{data}"

    app_key = "app4you2love"
    env_key = "production"
    PLOGGER << "<<<\n"
    PLOGGER << data
    PLOGGER << "<<<\n"

    http = Net::HTTP.new("api1.errplane.com", "8086")
    response = http.post("/api/v2/time_series/applications/#{app_key}/environments/#{env_key}?api_key=ignored", data)
    PLOGGER << "-response.code #{response.code}-\n"
  end

  ActiveSupport::Notifications.subscribe do |name, start, finish, id, payload|
    h = { :name => name, :start => start, :finish => finish, :nid => id, :payload => payload }
  #  Rails.logger.error("Pushing!")

    ErrplaneNotifications.notifications.push  h
    # post_data("controllers/ExceptionsController/action/index 1336.819 1344112120\ncontrollers/ExceptionsController/action/index/views 919.1610000000001 1344112120\ncontrollers/ExceptionsController/action/index/db 106.22600000000004 134411212\n")
  #  Rails.logger.error("Pushed!-#{ErrplaneNotifications.notifications.inspect}")
  end

  def spawn_thread()
    Thread.new do
      while true
        sleep(2) # Take a little break, so an idle running worker doesn't keep the system busy
        begin
          # PLOGGER << "Waking up !-#{ErrplaneNotifications.notifications.inspect}"
          out = []
          while !ErrplaneNotifications.notifications.empty?
            PLOGGER << "not empty!"
            n = ErrplaneNotifications.notifications.pop
            timediff = n[:finish] - n[:start]
            PLOGGER <<  "------------------------\n"
            s = ["notification2:", n[:name], timediff, n[:nid], n[:payload], "\n"].join("\t")
            PLOGGER << s
            if( n[:name].to_s == "process_action.action_controller" )
              out << "controllers/#{n[:payload][:controller]}/actions/#{n[:payload][:action]} #{(timediff*1000).ceil} #{n[:finish].utc.to_i}"
              out << "controllers/#{n[:payload][:controller]}/actions/#{n[:payload][:action]}/views #{n[:payload][:view_runtime].ceil} #{n[:finish].utc.to_i }"
              out << "controllers/#{n[:payload][:controller]}/actions/#{n[:payload][:action]}/db #{n[:payload][:db_runtime].ceil} #{n[:finish].utc.to_i }"
              out << "controllers #{(timediff*1000).ceil} #{n[:finish].utc.to_i }"
              out << "views #{n[:payload][:view_runtime].ceil} #{n[:finish].utc.to_i }"
              out << "db #{n[:payload][:db_runtime].ceil} #{n[:finish].utc.to_i }"
              post_data(out.join("\n"))
            else
              PLOGGER << "name-#{n[:name]}-"
            end
            PLOGGER << "Popped!"
          end
          #POST HERE
          #post_data(out.join("\n"))
        rescue => e
          PLOGGER << "Error-#{e.inspect}\n"
        end
      end
    end
  end

  if defined?(PhusionPassenger)
    PhusionPassenger.on_event(:starting_worker_process) do |forked|
      if forked
        Errplane::NotificationsQueue.initialize
        spawn_thread()
      end
    end
  else
    Errplane::NotificationsQueue.initialize
    spawn_thread()
  end
end
