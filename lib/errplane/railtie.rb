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
            puts "Done. Check your email or http://errplane.com for the exception notice."
          else
            puts "Request failed: #{response}"

            env["HTTPS"] = "on"
            puts "Attempting to raise exception via HTTPS.."
            response = ::Rails.application.call(env)

            if response.try(:first) == 500
              puts "Done. Check your email or http://errplane.com for the exception notice."
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
        config.framework_version       = ::Rails::VERSION::STRING
      end

      if defined?(::ActionDispatch::DebugExceptions)
        require 'errplane/rails/middleware/hijack_render_exception'
        ::ActionDispatch::DebugExceptions.send(:include, Errplane::Rails::Middleware::HijackRenderException)
      elsif defined?(::ActionDispatch::ShowExceptions)
        require 'errplane/rails/middleware/hijack_render_exception'
        ::ActionDispatch::ShowExceptions.send(:include, Errplane::Rails::Middleware::HijackRenderException)
      end
    end
  end
end
