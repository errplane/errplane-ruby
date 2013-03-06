require "net/http"
require "net/https"
require "rubygems"
require "socket"
require "thread"
require "base64"

require "json" unless Hash.respond_to?(:to_json)

require "errplane/version"
require "errplane/logger"
require "errplane/exception_presenter"
require "errplane/max_queue"
require "errplane/configuration"
require "errplane/api"
require "errplane/backtrace"
require "errplane/worker"
require "errplane/rack"

require "errplane/railtie" if defined?(Rails::Railtie)

module Errplane
  class << self
    include Logger

    attr_writer :configuration
    attr_accessor :api

    def configure(silent = false)
      yield(configuration)
      self.api = Api.new
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def queue
      @queue ||= MaxQueue.new(configuration.queue_maximum_depth)
    end

    def report(name, params = {}, async = true)
      unless configuration.ignored_reports.find{ |msg| /#{msg}/ =~ name  }
        data = {
          :name => name.gsub(/\s+/, "_"),
          :timestamp => "now"
        }.merge(params)

        if async
          Errplane.queue.push(data)
        else
          Errplane.api.post(Errplane.process_line(data))
        end
      end
    end

    def report_deployment(context = nil, async = false)
      report("deployments", {:context => context}, async)
    end

    def heartbeat(name, interval)
      log :debug, "Starting heartbeat '#{name}' on a #{interval} second interval."
      Thread.new do
        while true do
          log :debug, "Sleeping '#{name}' for #{interval} seconds."
          sleep(interval)
          report(name, :timestamp => "now")
        end
      end
    end

    def time(name, params = {})
      value = if block_given?
        start_time = Time.now
        yield
        ((Time.now - start_time)*1000).ceil
      else
        params[:value] || 0
      end

      report(name, :value => value)
    end

    def transmit_unless_ignorable(e, env = {})
      transmit(e, env) unless ignorable_exception?(e)
    end

    def transmit(e, env = {})
      begin
        env = errplane_request_data if env.empty? && defined? errplane_request_data
        exception_presenter = ExceptionPresenter.new(e, env)
        log :info, "Exception: #{exception_presenter.to_json[0..512]}..."

        Errplane.queue.push({
          :name => exception_presenter.time_series_name,
          :context => exception_presenter
        })
      rescue => e
        log :info, "[Errplane] Something went terribly wrong. Exception failed to take off! #{e.class}: #{e.message}"
      end
    end

    def current_timestamp
      Time.now.utc.to_i
    end

    def process_line(line)
      data = "#{line[:name]} #{line[:value] || 1} #{line[:timestamp] || "now"}"
      data = "#{data} #{Base64.strict_encode64(line[:context].to_json)}" if line[:context]
      data
    end

    def ignorable_exception?(e)
      configuration.ignore_current_environment? ||
      !!configuration.ignored_exception_messages.find{ |msg| /.*#{msg}.*/ =~ e.message  } ||
      configuration.ignored_exceptions.include?(e.class.to_s)
    end

    def rescue(&block)
      block.call
    rescue StandardError => e
      if configuration.ignore_current_environment?
        raise(e)
      else
        transmit_unless_ignorable(e)
      end
    end

    def rescue_and_reraise(&block)
      block.call
    rescue StandardError => e
      transmit_unless_ignorable(e)
      raise(e)
    end
  end
end

require "errplane/sinatra" if defined?(Sinatra::Request)
