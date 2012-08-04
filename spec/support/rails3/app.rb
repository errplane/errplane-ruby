require 'action_controller/railtie'

app = Class.new(Rails::Application)
app.config.secret_token = '1234567890abcdef1234567890abcdef'
app.config.session_store :cookie_store, :key => '_myapp_session'
app.config.active_support.deprecation = :log
app.config.root = File.dirname(__FILE__)
Rails.backtrace_cleaner.remove_silencers!
app.initialize!

app.routes.draw do
  resources :widgets
end

Errplane.configure do |config|
  config.api_key = "f123-e456-d789c012"
  config.application_id = "b12r8c72"
end

class ApplicationController < ActionController::Base; end
class WidgetsController < ApplicationController
  def index; render :nothing => true; end
  def new; return 1/0; end
end

Object.const_set(:ApplicationHelper, Module.new)
