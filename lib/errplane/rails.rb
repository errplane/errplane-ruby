require 'action_controller'
require 'errplane'
require 'errplane/rails/middleware/hijack_rescue_action_everywhere'
require 'errplane/rails/air_traffic_controller'

module Errplane
  module Rails
    def self.initialize
      ActionController::Base.send(:include, Errplane::Rails::AirTrafficController)
      ActionController::Base.send(:include, Errplane::Rails::Middleware::HijackRescueActionEverywhere)

      ::Rails.configuration.middleware.insert_after 'ActionController::Failsafe', Errplane::Rack

      Errplane.configure(true) do |config|
        config.logger                ||= ::Rails.logger
        config.debug                   = true
        config.rails_environment     ||= ::Rails.env
        config.application_root      ||= ::Rails.root
        config.application_name      ||= "Application"
        config.framework               = "Rails"
        config.framework_version       = ::Rails.version
      end
    end
  end
end

Errplane::Rails.initialize
