require 'net/http'
require 'net/https'
require 'rubygems'

require "json" unless Hash.respond_to?(:to_json)

require "errplane/version"
require "errplane/logger"
require "errplane/black_box"
require "errplane/configuration"
require "errplane/transmitter"
require "errplane/backtrace"
require "errplane/rack"

require "errplane/railtie" if defined?(Rails::Railtie)
require "errplane/sinatra" if defined?(Sinatra::Request)

module Errplane
  class << self
    include Logger

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
        log :info, "Transmitter: #{transmitter.inspect}"
        log :info, "Black Box: #{black_box.to_json}"
        log :info, "Ignorable Exception? #{ignorable_exception?(e)}"
        log :info, "Environment: #{ENV.to_hash}"

        transmitter.relay(black_box) unless ignorable_exception?(e)
      rescue => e
        log :info, "[Errplane] Something went terribly wrong. Exception failed to take off! #{e.class}: #{e.message}"
      end
    end

    def transmit(e, env = {})
      begin
        black_box = if e.is_a?(String)
          assemble_black_box_for(Exception.new(e), env)
        else
          assemble_black_box_for(e, env)
        end

        log :info, "Transmitter: #{transmitter.inspect}"
        log :info, "Black Box: #{black_box.to_json}"
        log :info, "Environment: #{ENV.to_hash}"
        transmitter.relay(black_box)
      rescue => e
        log :info, "[Errplane] Something went terribly wrong. Exception failed to take off! #{e.class}: #{e.message}"
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
      log :info, "OPTS: #{opts}"
      e = e.continued_exception if e.respond_to?(:continued_exception)
      e = e.original_exception if e.respond_to?(:original_exception)
      opts = opts.merge(:exception => e)
      black_box = BlackBox.new(opts)
    end
  end
end
