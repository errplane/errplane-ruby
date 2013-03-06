require "base64"
require "socket"

module Errplane
  class ExceptionPresenter
    attr_accessor :hash

    attr_reader :exception
    attr_reader :backtrace
    attr_reader :params
    attr_reader :session_data
    attr_reader :controller
    attr_reader :action
    attr_reader :request_url
    attr_reader :user_agent
    attr_reader :custom_data

    def initialize(e, params = {})
      e = e.continued_exception if e.respond_to?(:continued_exception)
      e = e.original_exception if e.respond_to?(:original_exception)

      @exception = e.is_a?(String) ? Exception.new(e) : e
      @backtrace = Errplane::Backtrace.new(@exception.backtrace).to_a || []
      @params = params[:params]
      @session_data = params[:session_data]
      @controller = params[:controller]
      @action = params[:action]
      @request_url = params[:request_url]
      @user_agent = params[:user_agent]
      @custom_data = params[:custom_data] || {}
      @environment_variables = ENV.to_hash || {}
    end

    def to_json
      payload = {
        :time => Time.now.utc.to_i,
        :application_name => Errplane.configuration.application_name,
        :application_root => Errplane.configuration.application_root,
        :framework => Errplane.configuration.framework,
        :framework_version => Errplane.configuration.framework_version,
        :message => @exception.message,
        :backtrace => @backtrace,
        :exception_class => @exception.class.to_s,
        :language => "Ruby",
        :language_version => "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}",
        :reporter => reporter,
        :hostname => Socket.gethostname,
        :custom_data => @custom_data
      }

      payload[:environment_variables] = @environment_variables.reject do |k,v|
        Errplane.configuration.environment_variable_filters.any? { |filter| k =~ filter }
      end

      Errplane.configuration.add_custom_exception_data(self)

      payload[:request_data] = request_data if @controller || @action || !@params.blank?
      payload[:hash] = calculate_hash
      payload.to_json
    end

    def calculate_hash
      if hash
        hash
      elsif Errplane.configuration.aggregated_exception_classes.include?(@exception.class.to_s)
        Digest::SHA1.hexdigest(@exception.class.to_s)
      else
        Digest::SHA1.hexdigest(@exception.class.to_s + @backtrace.first.to_s)
      end
    end

    def time_series_name
      "exceptions/" + calculate_hash
    end

    def context
      Base64.strict_encode64(to_json)
    end

    def reporter
      {
        :name => "Errplane",
        :version => Errplane::VERSION,
        :url => "https://github.com/errplane/errplane-ruby"
      }
    end

    def request_data
      {
        :params => @params,
        :session_data => @session_data,
        :controller => @controller,
        :action => @action,
        :request_url => @request_url,
        :user_agent => @user_agent
      }
    end
  end
end
