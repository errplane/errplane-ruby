$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
ENV["RAILS_ENV"] ||= "test"

require 'rails'

require 'bundler/setup'
Bundler.require

require "fakeweb"
FakeWeb.allow_net_connect = false

if defined? Rails
  puts "Loading Rails v#{Rails.version}..."

  require "support/rails3/app"
  require "rspec/rails"
else
  puts "ERROR: Rails could not be loaded."
  exit
end
