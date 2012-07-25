module Errplane
  class Configuration
    attr_accessor :api_key
    attr_accessor :api_host
    attr_accessor :app_host
    attr_accessor :application_id
    attr_accessor :application_name
    attr_accessor :application_root
    attr_accessor :syslogd_port

    attr_accessor :logger
    attr_accessor :rails_environment
    attr_accessor :framework
    attr_accessor :framework_version
    attr_accessor :language
    attr_accessor :language_version
    attr_accessor :ignored_exceptions
    attr_accessor :ignored_environments
    attr_accessor :ignored_user_agents

    attr_accessor :environment_variables

    attr_accessor :debug
    attr_accessor :reraise_global_exceptions

    DEFAULTS = {
      :api_host => "api.errplane.com",
      :app_host => "app.errplane.com",
      :ignored_exceptions => %w{ActiveRecord::RecordNotFound
                                ActionController::RoutingError},
      :ignored_environments => %w{development test cucumber selenium},
      :ignored_user_agents => %w{GoogleBot}
    }

    def initialize
      @api_host = DEFAULTS[:api_host]
      @app_host = DEFAULTS[:app_host]
      @ignored_exceptions = DEFAULTS[:ignored_exceptions].dup
      @ignored_environments = DEFAULTS[:ignored_environments].dup
      @ignored_user_agents = DEFAULTS[:ignored_user_agents].dup
      @debug = false
      @rescue_global_exceptions = false
    end

    def debug?
      !!@debug
    end

    def reraise_global_exceptions?
      !!@reraise_global_exceptions
    end

    def ignore_user_agent?(incoming_user_agent)
      return false if self.ignored_user_agents.nil?
      self.ignored_user_agents.any? {|agent| incoming_user_agent =~ /#{agent}/}
    end

    def ignore_current_environment?
      self.ignored_environments.include?(self.rails_environment)
    end

    def get_logport
      puts "Acquiring port information from errplane"
      http = initialize_http_connection
      response = begin
                   url = "/api/v1/syslogds.txt?api_key=#{@api_key}"
                   http.get(url)
                 rescue Exception => e
                   puts e
                 end


      case response
      when Net::HTTPSuccess
        # Success
        response.body
      else
        # Failure
        ""
      end
    end

    def define_custom_exception_data(&block)
      @custom_exception_data_handler = block
    end

    def add_custom_exception_data(black_box)
      @custom_exception_data_handler.call(black_box) if @custom_exception_data_handler
    end

    private
    def initialize_http_connection
      Net::HTTP.new(@app_host, "80")
    end
  end
end
