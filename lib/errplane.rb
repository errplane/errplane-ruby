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
      transmitter.relay(assemble_black_box_for(exception)) unless ignorable_exception?(exception)
    end

    def ignorable_exception?(exception)
      configuration.ignore_current_environment? || configuration.ignored_exceptions.include?(exception.class.to_s)
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
