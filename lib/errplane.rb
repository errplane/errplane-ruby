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
require "errplane/sidekiq" if defined?(Sidekiq)

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

    def report(name, params = {}, udp = false)
      unless configuration.ignored_reports.find{ |msg| /#{msg}/ =~ name  }
        data = generate_data(name, params)
        udp ? Errplane.api.send(data) : Errplane.queue.push(data)
      end
    end

    def aggregate(name, params = {})
      Errplane.api.send generate_data(name, params), "t"
    end

    def sum(name, params = {})
      Errplane.api.send generate_data(name, params), "c"
    end

    def destringify_value(value)
      if value.is_a?(String)
        return value.to_f if value =~ /\./
        return value.to_i
      else
        return value
      end
    end

    def generate_data(name, params)
      value = destringify_value(params[:value])
      point = {:v => value || 1}
      point[:t] = params[:timestamp] unless params[:timestamp].nil?

      if context = params[:context]
        point[:c] = params[:context].is_a?(String) ? params[:context] : params[:context].to_json
      end

      if dimensions = params[:dimensions]
        point[:d] = Hash[params[:dimensions].map {|k,v| [k.to_s, v.to_s]}]
      end

      {
        :n => name.gsub(/\s+/, "_"),
        :p => [point]
      }
    end

    def report_deployment(context = nil, udp = false)
      report("deployments", {:context => context}, udp)
    end

    def heartbeat(name, interval, params)
      log :debug, "Starting heartbeat '#{name}' on a #{interval} second interval."
      Thread.new do
        while true do
          log :debug, "Sleeping '#{name}' for #{interval} seconds."
          sleep(interval)
          report(name, :dimensions => params[:dimensions], :context => params[:context])
        end
      end
    end

    def time(name, params = {})
      time_elapsed = if block_given?
        start_time = Time.now
        yield_value = yield
        ((Time.now - start_time)*1000).ceil
      else
        params[:value] || 0
      end

      report(name, :value => time_elapsed)

      yield_value
    end

    def report_exception_unless_ignorable(e, env = {})
      report_exception(e, env) unless ignorable_exception?(e)
    end
    alias_method :transmit_unless_ignorable, :report_exception_unless_ignorable

    def report_exception(e, env = {})
      begin
        env = errplane_request_data if env.empty? && defined? errplane_request_data
        exception_presenter = ExceptionPresenter.new(e, env)
        log :info, "Exception: #{exception_presenter.to_json[0..512]}..."

        Errplane.queue.push({
          :n => "exceptions",
          :p => [{
            :v => 1,
            :c => exception_presenter.context.to_json,
            :d => exception_presenter.dimensions
          }]
        })
      rescue => e
        log :info, "[Errplane] Something went terribly wrong. Exception failed to take off! #{e.class}: #{e.message}"
      end
    end
    alias_method :transmit, :report_exception

    def current_timestamp
      Time.now.utc.to_i
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

unless defined?(Base64.strict_encode64)
  module Base64
    def strict_encode64(str)
      return encode64(str).gsub("\n", "")
    end
  end
end
