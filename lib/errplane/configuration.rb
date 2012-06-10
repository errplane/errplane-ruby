module Errplane
  class Configuration
    attr_accessor :api_key
    attr_accessor :api_host
    attr_accessor :application_id

    attr_accessor :logger
    attr_accessor :rails_environment
    attr_accessor :rails_root
    attr_accessor :framework
    attr_accessor :ignored_exceptions
    attr_accessor :ignored_environments

    DEFAULT_API_HOST = "api.errplane.com"
    DEFAULT_IGNORED_EXCEPTIONS = %w{ActiveRecord::RecordNotFound
                                    ActionController::RoutingError}
    DEFAULT_IGNORED_ENVIRONMENTS = %w{development test cucumber selenium}

    def initialize
      @api_host = DEFAULT_API_HOST
      @ignored_exceptions = DEFAULT_IGNORED_EXCEPTIONS.dup
      @ignored_environments = DEFAULT_IGNORED_ENVIRONMENTS.dup
    end

    def ignore_current_environment?
      return self.ignored_environments.include?(self.rails_environment)
    end
  end
end
