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
end

require 'bundler/setup'
Bundler.require

require "fakeweb"
FakeWeb.allow_net_connect = false

if defined? Rails
  puts "Loading Rails v#{Rails.version}..."

  if Rails.version.to_f < 3.0
    Gem::Deprecate.skip = true

    RAILS_ROOT = "#{File.dirname(__FILE__)}/support/rails2"
    require "#{RAILS_ROOT}/config/environment"
    require "spec/rails"
  elsif Rails.version.to_f < 4.0
    require "support/rails3/app"
    require "rspec/rails"
  else
    require "support/rails4/app"
    require "rspec/rails"
  end
end
