require 'errplane'
require 'rails'

module Errplane
  class Railtie < ::Rails::Railtie
    rake_tasks do
      namespace :errplane do
        task :test => :environment do
          if Errplane.configuration.api_key.nil?
            puts "Hey, you need to define an API key first. Run `rails g errplane <api-key>` if you didn't already."
            exit
          end

          Errplane.configure do |config|
            config.ignored_environments = []
          end

          class ::ErrplaneSampleException < Exception; end;

          require ::Rails.root.join("app/controllers/application_controller.rb")

          puts "Setting up ApplicationController.."
          class ::ApplicationController
            prepend_before_filter :raise_sample_exception

            def raise_sample_exception
              raise ::ErrplaneSampleException.new("If you see this, Errplane is working.")
            end

            def errplane_dummy_action; end
          end

          ::Rails.application.routes_reloader.execute_if_updated
          ::Rails.application.routes.draw do
            match "errplane_test" => 'application#errplane_dummy_action'
          end

          puts "Generating sample request.."
          env = ::Rack::MockRequest.env_for("/errplane_test")

          puts "Attempting to raise exception via HTTP.."
          response = ::Rails.application.call(env)

          if response.try(:first) == 500
            if Errplane.transmitter.last_response.nil?
              puts "Uh oh. Your app threw an exception, but we didn't get a response. Check your network connection and try again."
            elsif Errplane.transmitter.last_response.code == "201"
              puts "Done. Check your email or http://errplane.com for the exception notice."
            else
              puts "That didn't work. The Errplane API said: #{Errplane.transmitter.last_response.body}"
            end
          else
            puts "Request failed: #{response}"

            env["HTTPS"] = "on"
            puts "Attempting to raise exception via HTTPS.."
            response = ::Rails.application.call(env)

            if response.try(:first) == 500
              if Errplane.transmitter.last_response.nil?
                puts "Uh oh. Your app threw an exception, but we didn't get a response. Check your network connection and try again."
              elsif Errplane.transmitter.last_response.code == "201"
                puts "Done. Check your email or http://errplane.com for the exception notice."
              else
                puts "That didn't work. The Errplane API said: #{Errplane.transmitter.last_response.body}"
              end
            else
              puts "Request failed: #{response}"
              puts "We didn't get the exception we were expecting. Contact support@errplane.com and send them all of this output."
            end
          end
        end
      end
    end

    initializer "errplane.insert_rack_middleware" do |app|
      app.config.middleware.insert 0, Errplane::Rack
    end

    config.after_initialize do
      Errplane.configure(true) do |config|
        config.logger                ||= ::Rails.logger
        config.rails_environment     ||= ::Rails.env
        config.application_root      ||= ::Rails.root
        config.application_name      ||= ::Rails.application.class.parent_name
        config.framework               = "Rails"
        config.framework_version       = ::Rails.version
      end

      ActiveSupport.on_load(:action_controller) do
        require 'errplane/rails/air_traffic_controller'
        include Errplane::Rails::AirTrafficController
        require 'errplane/rails/instrumentation'
        include Errplane::Rails::Instrumentation
      end

      if defined?(::ActionDispatch::DebugExceptions)
        require 'errplane/rails/middleware/hijack_render_exception'
        ::ActionDispatch::DebugExceptions.send(:include, Errplane::Rails::Middleware::HijackRenderException)
      elsif defined?(::ActionDispatch::ShowExceptions)
        require 'errplane/rails/middleware/hijack_render_exception'
        ::ActionDispatch::ShowExceptions.send(:include, Errplane::Rails::Middleware::HijackRenderException)
      end

      if defined?(ActiveSupport::Notifications)
        ActiveSupport::Notifications.subscribe "process_action.action_controller" do |name, start, finish, id, payload|
          if Errplane.configuration.instrumentation_enabled?
            h = { :name => name,
                  :start => start,
                  :finish => finish,
                  :nid => id,
                  :payload => payload,
                  :source => "active_support"}
            Errplane.queue.push(h)
          end
        end
      end

      if defined?(PhusionPassenger)
        PhusionPassenger.on_event(:starting_worker_process) do |forked|
          Errplane::Worker.spawn_threads() if forked
        end
      else
        Errplane::Worker.spawn_threads()
      end
    end
  end
end
