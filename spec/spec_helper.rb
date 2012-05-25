require 'rubygems'
require 'bundler'

Bundler.require :default, :development

require 'capybara/rspec'
require 'webmock/rspec'

Combustion.initialize!

require 'rspec/rails'
require 'capybara/rails'

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end

class Combustion::Application < Rails::Application
  config.action_dispatch.show_exceptions = false
end
