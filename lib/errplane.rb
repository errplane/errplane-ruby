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

require "errplane/railtie" #if defined? Rails::Railtie
require "errplane/sinatra" if defined? Sinatra::Request

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

    def transmit_unless_ignorable(e, env)
      begin
        black_box = assemble_black_box_for(e)
        configuration.logger.info("\nTransmitter: #{transmitter.inspect}") if configuration.debug?
        configuration.logger.info("\nBlack Box: #{black_box.to_json}") if configuration.debug?
        configuration.logger.info("\nIgnorable Exception? #{ignorable_exception?(e)}") if configuration.debug?
        configuration.logger.info("\nEnvironment: #{ENV.to_hash}") if configuration.debug?

        transmitter.relay(black_box) unless ignorable_exception?(e)
      rescue
        configuration.logger.info("[Errplane] Something went terribly wrong. Exception failed to take off.")
      end
    end

    def transmit(e)
      begin
        black_box = if e.is_a?(String)
          assemble_black_box_for(Exception.new(e))
        else
          assemble_black_box_for(e)
        end

        configuration.logger.info("\nTransmitter: #{transmitter.inspect}") if configuration.debug?
        configuration.logger.info("\nBlack Box: #{black_box.to_json}") if configuration.debug?
        configuration.logger.info("\nIgnorable Exception? #{ignorable_exception?(e)}") if configuration.debug?
        configuration.logger.info("\nEnvironment: #{ENV.to_hash}") if configuration.debug?
        transmitter.relay(black_box)
      rescue
        configuration.logger.info("[Errplane] Something went terribly wrong. Exception failed to take off.")
      end
    end

    def ignorable_exception?(e)
      configuration.ignore_current_environment? || configuration.ignored_exceptions.include?(e.class.to_s)
    end

    private
    def assemble_black_box_for(e, options = {})
      exception = unwrap_exception(e)
      black_box = BlackBox.new(:exception => exception)
    end

    def unwrap_exception(e)
      if e.respond_to?(:original_exception)
        e.original_exception
      elsif e.respond_to?(:continued_exception)
        e.continued_exception
      else
        e
      end
    end
  end
end
