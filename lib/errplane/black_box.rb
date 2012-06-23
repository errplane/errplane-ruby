module Errplane
  class BlackBox
    attr_reader :exception

    def initialize(params = {})
      @exception = params[:exception]
    end

    def to_json
      {
        :time => Time.now.to_i,
        :message => @exception.message,
        :backtrace => @exception.backtrace || [],
        :exception_class => @exception.class.to_s,
        :application_name => Errplane.configuration.application_name,
        :rails_root => Errplane.configuration.rails_root,
        :language => Errplane.configuration.language,
        :language_version => Errplane.configuration.language_version,
        :framework => Errplane.configuration.framework,
        :framework_version => Errplane.configuration.framework_version,
        :environment_variables => Errplane.configuration.environment_variables.to_hash,
      }.to_json
    end
  end
end
