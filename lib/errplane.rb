require 'net/http'
require 'net/https'
require 'rubygems'

begin
  require 'active_support'
  require 'active_support/core_ext'
rescue LoadError
  require 'activesupport'
  require 'activesupport/core_ext'
end

require "errplane/version"
require "errplane/black_box"
require "errplane/configuration"
require "errplane/transmitter"
require "errplane/rack"

require "errplane/railtie" #if defined?(Rails)

module Errplane
  API_HOST = "api.errz.co"

  class << self
    attr_writer :configuration
    attr_accessor :transmitter

    def configure(silent = false)
      yield(configuration)
      self.transmitter = Transmitter.new(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def transmit_to_api(exception)
      transmitter.relay(assemble_black_box_for(exception))
    end

    private
    def assemble_black_box_for(exception, options = {})
      exception = unwrap_exception(exception)
      black_box = BlackBox.new(exception: exception)
    end

    def unwrap_exception(exception)
      if exception.respond_to?(:original_exception)
        exception.original_exception
      elsif exception.respond_to?(:continued_exception)
        exception.continued_exception
      else
        exception
      end
    end
  end
end
