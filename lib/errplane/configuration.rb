module Errplane
  class Configuration
    attr_accessor :api_key
    attr_accessor :api_host
    attr_accessor :application_id

    attr_accessor :logger
    attr_accessor :rails_environment
    attr_accessor :rails_root
    attr_accessor :framework
    attr_accessor :framework_version
    attr_accessor :language
    attr_accessor :language_version
    attr_accessor :ignored_exceptions
    attr_accessor :ignored_environments

    DEFAULTS = {
      :api_host => "api.errplane.com",
      :ignored_exceptions => %w{ActiveRecord::RecordNotFound
                                ActionController::RoutingError},
      :ignored_environments => %w{development test cucumber selenium}
    }

    def initialize
      @api_host = DEFAULTS[:api_host]
      @ignored_exceptions = DEFAULTS[:ignored_exceptions].dup
      @ignored_environments = DEFAULTS[:ignored_environments].dup
    end

    def ignore_current_environment?
      self.ignored_environments.include?(self.rails_environment)
    end
  end
end
