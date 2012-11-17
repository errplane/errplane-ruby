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
      @params = params[:params]
      @session_data = params[:session_data]
      @controller = params[:controller]
      @action = params[:action]
      @request_url = params[:request_url]
      @user_agent = params[:user_agent]
      @custom_data = params[:custom_data] || {}
      @environment_variables = params[:environment_variables] || {}
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
        :reporter => reporter,
        :custom_data => @custom_data
      }
      payload[:environment_variables] = @environment_variables

      Errplane.configuration.add_custom_exception_data(self)

      payload[:request_data] = request_data if @controller || @action || !@params.blank?
      payload[:hash] = hash if hash
      if Errplane.configuration.aggregated_exception_classes.include?(@exception.class.to_s)
        payload[:hash] = Digest::SHA1.hexdigest(@exception.class.to_s)
      end

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
