module Errplane
  class BlackBox
    attr_accessor :hash
    attr_reader :exception
    attr_reader :params
    attr_reader :session_data
    attr_reader :controller
    attr_reader :action
    attr_reader :request_url
    attr_reader :custom_data

    def initialize(params = {})
      @exception = params[:exception]
      @params = params[:params] || {}
      @session_data = params[:session_data] || {}
      @controller = params[:controller]
      @action = params[:action]
      @request_url = params[:request_url]
      @custom_data = params[:custom_data] || {}
    end

    def to_json
      paylaod = {
        :time => Time.now.to_i,
        :application_name => Errplane.configuration.application_name,
        :application_root => Errplane.configuration.application_root,
        :framework => Errplane.configuration.framework,
        :framework_version => Errplane.configuration.framework_version,
        :message => @exception.message,
        :backtrace => @exception.backtrace || [],
        :exception_class => @exception.class.to_s,
        :language => "Ruby",
        :language_version => "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}",
        :environment_variables => ENV.to_hash,
        :reporter => reporter,
        :custom_data => @custom_data
      }

      Errplane.configuration.add_custom_exception_data(self)

      paylaod[:request_data] = request_data if @controller || @action || !params.empty?
      paylaod[:hash] = hash if hash

      paylaod.to_json
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
        :request_url => @request_url
      }
    end
  end
end
