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
            config.debug = true
            config.ignored_environments = []
          end

          data = [{:n => "tests", :p => [{:v => 1}]}]
          if Errplane.api.post(data)
            puts "Test data sent successfully!"
          else
            puts "Test failed! Check your network connection and try again."
          end
        end

        task :diagnose => :environment do
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

          10.times do
            sleep 1
            break unless Errplane.api.last_response.nil?
          end

          if response.try(:first) == 500
            if Errplane.api.last_response.nil?
              puts "Uh oh. Your app threw an exception, but we didn't get a response. Check your network connection and try again."
            elsif Errplane.api.last_response.code == "201"
              puts "Done. Check your email or http://errplane.com for the exception notice."
            else
              puts "That didn't work. The Errplane API said: #{Errplane.api.last_response.body}"
            end
          else
            puts "Request failed: #{response}"

            env["HTTPS"] = "on"
            puts "Attempting to raise exception via HTTPS.."
            response = ::Rails.application.call(env)

            if response.try(:first) == 500
              if Errplane.api.last_response.nil?
                puts "Uh oh. Your app threw an exception, but we didn't get a response. Check your network connection and try again."
              elsif Errplane.api.last_response.code == "201"
                puts "Done. Check your email or http://errplane.com for the exception notice."
              else
                puts "That didn't work. The Errplane API said: #{Errplane.api.last_response.body}"
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
        config.environment           ||= ::Rails.env
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
          if Errplane.configuration.instrumentation_enabled  && ! Errplane.configuration.ignore_current_environment?
            timestamp = finish.utc.to_i
            controller_runtime = ((finish - start)*1000).ceil
            view_runtime = (payload[:view_runtime] || 0).ceil
            db_runtime = (payload[:db_runtime] || 0).ceil
            controller_name = payload[:controller]
            action_name = payload[:action]

            dimensions = {:method => "#{controller_name}##{action_name}", :server => Socket.gethostname}
            Errplane.aggregate "controllers", :value => controller_runtime, :dimensions => dimensions
            Errplane.aggregate "views", :value => view_runtime, :dimensions => dimensions
            Errplane.aggregate "db", :value => db_runtime, :dimensions => dimensions
          end
        end
      end
    end
  end
end
