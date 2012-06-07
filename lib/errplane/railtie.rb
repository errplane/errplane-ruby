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
        config.logger           ||= ::Rails.logger
        config.environment_name ||= ::Rails.env
        config.project_root     ||= ::Rails.root
        config.framework        = "Rails: #{::Rails::VERSION::STRING}"
      end
    end
  end
end
