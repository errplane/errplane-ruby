require "net/http"
require "net/https"
require "rubygems"
require "socket"
require "thread"

require "json" unless Hash.respond_to?(:to_json)

require "errplane/version"
require "errplane/logger"
require "errplane/black_box"
require "errplane/max_queue"
require "errplane/configuration"
require "errplane/transmitter"
require "errplane/backtrace"
require "errplane/worker"
require "errplane/rack"

require "errplane/railtie" if defined?(Rails::Railtie)

module Errplane
  class << self
    include Logger

    attr_writer :configuration
    attr_accessor :transmitter
    attr_accessor :queue

    def configure(silent = false)
      yield(configuration)
      self.transmitter = Transmitter.new(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def queue
      @queue ||= MaxQueue.new(configuration.queue_maximum_depth)
    end

    def report(name, params = {})
      Errplane.queue.push({
        :name => name,
        :source => "custom",
        :timestamp => current_timestamp
      }.merge(params))
    end

    def heartbeat(name, interval)
      log :debug, "Starting heartbeat '#{name}' on a #{interval} second interval."
      Thread.new do
        while true do
          log :debug, "Sleeping '#{name}' for #{interval} seconds."
          sleep(interval)
          report(name)
        end
      end
    end

    def time(name = nil)
      start_time = Time.now
      yield
      elapsed_time = Time.now - start_time
      report("timed_blocks/#{(name || Socket.gethostname)}", :value => (elapsed_time*1000).ceil)
    end

    def transmit_unless_ignorable(e, env)
      begin
        black_box = assemble_black_box_for(e, env)
        log :info, "Transmitter: #{transmitter.inspect}"
        log :info, "Black Box: #{black_box.to_json}"
        log :info, "Ignorable Exception? #{ignorable_exception?(e)}"
        log :info, "Environment: #{ENV.to_hash}"

        transmitter.enqueue(black_box) unless ignorable_exception?(e)
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
        transmitter.enqueue(black_box)
      rescue => e
        log :info, "[Errplane] Something went terribly wrong. Exception failed to take off! #{e.class}: #{e.message}"
      end
    end

    def current_timestamp
      Time.now.utc.to_i
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
      opts[:environment_variables] = ENV.to_hash
      black_box = BlackBox.new(opts)
    end
  end
end

require "errplane/sinatra" if defined?(Sinatra::Request)
