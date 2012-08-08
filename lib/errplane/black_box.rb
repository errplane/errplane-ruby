module Errplane
  class BlackBox
    attr_accessor :hash
    attr_reader :exception
    attr_reader :params
    attr_reader :session_data
    attr_reader :controller
    attr_reader :action
    attr_reader :request_url
    attr_reader :user_agent
    attr_reader :custom_data

    def initialize(params = {})
      @exception = params[:exception]
      @params = params[:params] ||   params["rack.request.query_hash"] || {}
      @session_data = params[:session_data] || params["rack.session"] || {}
      @controller = params[:controller]
      @action = params[:action] || params["REQUEST_PATH"]
      @request_url = params[:request_url] || params["REQUEST_PATH"]
      @user_agent = params[:user_agent] || params["HTTP_USER_AGENT"]
      @custom_data = params[:custom_data] || {}
    end

    def to_json
      payload = {
        :time => Time.now.to_i,
        :application_name => Errplane.configuration.application_name,
        :application_root => Errplane.configuration.application_root,
        :framework => Errplane.configuration.framework,
        :framework_version => Errplane.configuration.framework_version,
        :message => @exception.message,
        :backtrace => Errplane::Backtrace.new(@exception.backtrace).to_a || [],
        :exception_class => @exception.class.to_s,
        :language => "Ruby",
        :language_version => "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}",
        :environment_variables => ENV.to_hash,
        :reporter => reporter,
        :custom_data => @custom_data
      }

      Errplane.configuration.add_custom_exception_data(self)

      payload[:request_data] = request_data if @controller || @action || !params.empty?
      payload[:hash] = hash if hash

      payload.to_json
    end

    def reporter
      {
        :name => "Errplane",
        :version => Errplane::VERSION,
        :url => "https://github.com/errplane/gem"
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
