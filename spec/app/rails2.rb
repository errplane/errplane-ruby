RAILS_ROOT = File.dirname(__FILE__)

module Rails
  class << self
    def vendor_rails?; return false; end
  end
end

Rails::Initializer.run do |config|
  # config.time_zone = 'UTC'
  # config.cache_classes = true
  # config.whiny_nils = true
  # config.action_controller.consider_all_requests_local = true
  # config.action_controller.perform_caching             = false
  # config.action_view.cache_template_loading            = true
  # config.action_controller.allow_forgery_protection    = false
  # config.action_mailer.delivery_method = :test
  config.frameworks = [ :action_controller, :active_resource ]
  config.action_controller.session = { :key => "_myapp_session", :secret => "1234567890abcdef1234567890abcdef" }
end

ActionController::Base.cookie_verifier_secret = '1234567890abcdef1234567890abcdef'
ActionController::Base.session = {
  :key         => '_myapp_session',
  :secret      => '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'
}

Errplane.configure do |config|
  config.api_key = "f123-e456-d789c012"
  config.application_id = "b12r8c72"
  config.ignored_environments = []
end

class ApplicationController < ActionController::Base; end
class WidgetsController < ApplicationController
  def index; render :nothing => true; end
  def new; return 1/0; end
end
