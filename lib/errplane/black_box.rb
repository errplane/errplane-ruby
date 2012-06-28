module Errplane
  class BlackBox
    attr_reader :exception

    def initialize(params = {})
      @exception = params[:exception]
    end

    def to_json
      {
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
        :environment_variables => ENV.to_hash
      }.to_json
    end
  end
end
