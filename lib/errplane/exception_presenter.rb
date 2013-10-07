require "base64"
require "socket"

module Errplane
  class ExceptionPresenter
    attr_accessor :hash

    attr_reader :exception
    attr_reader :backtrace
    attr_reader :params
    attr_reader :session_data
    attr_reader :current_user
    attr_reader :controller
    attr_reader :action
    attr_reader :request_url
    attr_reader :referer
    attr_reader :remote_ip
    attr_reader :user_agent
    attr_reader :custom_data

    def initialize(e, params = {})
      e = e.continued_exception if e.respond_to?(:continued_exception)
      e = e.original_exception if e.respond_to?(:original_exception)

      @exception = e.is_a?(String) ? Exception.new(e) : e
      @backtrace = Errplane::Backtrace.new(@exception.backtrace)
      @params = params[:params]
      @session_data = params[:session_data] || {}
      @current_user = params[:current_user]
      @controller = params[:controller]
      @action = params[:action]
      @request_url = params[:request_url]
      @user_agent = params[:user_agent]
      @referer = params[:referer]
      @remote_ip = params[:remote_ip]
      @custom_data = params[:custom_data] || {}
      @environment_variables = ENV.to_hash || {}
      @dimensions = {}
    end

    def context
      c = {
        :time => Time.now.utc.to_i,
        :application_name => Errplane.configuration.application_name,
        :application_root => Errplane.configuration.application_root,
        :framework => Errplane.configuration.framework,
        :framework_version => Errplane.configuration.framework_version,
        :message => @exception.message,
        :backtrace => @backtrace.to_a,
        :language => "Ruby",
        :language_version => "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}",
        :reporter => reporter,
        :custom_data => @custom_data
      }

      c[:environment_variables] = @environment_variables.reject do |k,v|
        Errplane.configuration.environment_variable_filters.any? { |filter| k =~ filter }
      end

      Errplane.configuration.add_custom_exception_data(self)

      c[:request_data] = request_data if @controller || @action || !@params.blank?
      c
    end

    def dimensions
      d = {
        :class => @exception.class.to_s,
        :method => "#{@controller}##{@action}",
        :filename => File.basename(@backtrace.lines.first.try(:file)),
        :server => Socket.gethostname,
        :status => "open"
      }.merge(@dimensions)
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
        :referer => @referer,
        :remote_ip => @remote_ip,
        :user_agent => @user_agent
      }
    end
  end
end
