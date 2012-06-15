require 'errplane'
require 'rails'

module Errplane
  class Railtie < ::Rails::Railtie
    rake_tasks do
    end

    initializer "errplane.insert_rack_middleware" do |app|
      app.config.middleware.insert 0, Errplane::Rack
    end

    config.after_initialize do
      Errplane.configure(true) do |config|
        config.logger            ||= ::Rails.logger
        config.rails_environment ||= ::Rails.env
        config.rails_root        ||= ::Rails.root
        config.framework           = "Rails"
        config.framework_version   = ::Rails::VERSION::STRING
        config.language            = "Ruby"
        config.language_version    = RUBY_VERSION
      end

      if defined?(::ActionDispatch::DebugExceptions)
        require 'errplane/rails/middleware/hijack_render_exception'
        ::ActionDispatch::DebugExceptions.send(:include,Errplane::Rails::Middleware::HijackRenderException)
      elsif defined?(::ActionDispatch::ShowExceptions)
        require 'errplane/rails/middleware/hijack_render_exception'
        ::ActionDispatch::ShowExceptions.send(:include,Errplane::Rails::Middleware::HijackRenderException)
      end
    end
  end
end
