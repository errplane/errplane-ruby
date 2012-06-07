module Errplane
  class Configuration
    attr_accessor :api_key
    attr_accessor :application_id

    attr_accessor :logger
    attr_accessor :environment_name
    attr_accessor :project_root
    attr_accessor :framework
  end
end
