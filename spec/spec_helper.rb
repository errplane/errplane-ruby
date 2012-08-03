$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
ENV["RAILS_ENV"] ||= "test"

require 'rails/version'

if Rails::VERSION::MAJOR > 2
  require 'rails'
else
  module Rails
    class << self
      def vendor_rails?; return false; end
    end

    class Configuration
      def after_initialize; end
    end
    @@configuration = Configuration.new
  end
  require 'initializer'
  RAILS_ROOT = "#{File.dirname(__FILE__)}/rails2"
end

require 'bundler/setup'
Bundler.require

require "fakeweb"
FakeWeb.allow_net_connect = false

if defined? Rails
  puts "Loading Rails v#{Rails.version}..."

  unless Rails.version.to_f < 3.0
    require "app/rails3"
    require "rspec/rails"
  else
    require "rails2/config/environment"
    require "spec/rails"
  end
end
if defined? Sinatra
  require 'spec_helper_for_sinatra'
end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

