require 'net/http'
require 'net/https'
require 'rubygems'

require "errplane/version"
require "errplane/black_box"
require "errplane/configuration"
require "errplane/transmitter"
require "errplane/rack"

require "errplane/railtie" if defined? Rails::Railtie
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
        black_box = assemble_black_box_for(e, env)
        configuration.logger.info("\nTransmitter: #{transmitter.inspect}") if configuration.debug?
        configuration.logger.info("\nBlack Box: #{black_box.to_json}") if configuration.debug?
        configuration.logger.info("\nIgnorable Exception? #{ignorable_exception?(e)}") if configuration.debug?
        configuration.logger.info("\nEnvironment: #{ENV.to_hash}") if configuration.debug?

        transmitter.relay(black_box) unless ignorable_exception?(e)
      rescue => e
        configuration.logger.info("[Errplane] Something went terribly wrong. Exception failed to take off. 2-" + e.inspect)
      end
    end

    def transmit(e, env = {})
      begin
        black_box = if e.is_a?(String)
          assemble_black_box_for(Exception.new(e), env)
        else
          assemble_black_box_for(e, env)
        end

        configuration.logger.info("\nTransmitter: #{transmitter.inspect}") if configuration.debug?
        configuration.logger.info("\nBlack Box: #{black_box.to_json}") if configuration.debug?
        configuration.logger.info("\nIgnorable Exception? #{ignorable_exception?(e)}") if configuration.debug?
        configuration.logger.info("\nEnvironment: #{ENV.to_hash}") if configuration.debug?
        transmitter.relay(black_box)
      rescue => e
        configuration.logger.info("[Errplane] Something went terribly wrong. Exception failed to take off. 1-" + e.inspect)
      end
    end

    def ignorable_exception?(e)
      configuration.ignore_current_environment? || configuration.ignored_exceptions.include?(e.class.to_s)
    end

    def rescue(&block)
      block.call
    rescue StandardError => e
      if configuration.ignore_current_environment?
        raise(e)
      else
        transmit_unless_ignorable(e, {})
      end
    end

    def rescue_and_reraise(&block)
      block.call
    rescue StandardError => e
      transmit_unless_ignorable(e, {})
      raise(e)
    end

    private

    def assemble_black_box_for(e, opts = {})
      opts ||= {}
      configuration.logger.info("OPTS: #{opts}")
      e = e.continued_exception if e.respond_to?(:continued_exception)
      e = e.original_exception if e.respond_to?(:original_exception)
      opts = opts.merge(:exception => e)
      black_box = BlackBox.new(opts)
    end
  end
end
