#Forked from https://github.com/morgoth/airbrake_handler/blob/master/lib/airbrake_handler.rb
#Apache license please see above url for more details

require "chef/handler"
require "errplane"
require 'logger'

class ErrplaneChefHandler < Chef::Handler

  attr_accessor :options, :api_key, :ignore, :notify_host, :environment

  def initialize(options = {})
    @api_key     = options.delete(:api_key)
    @ignore      = options.delete(:ignore) || []
    @options     = options
    @environment = options.delete(:env) || "production"
  end

  def report
    if run_status.failed? && !ignore_exception?(run_status.exception)
      Chef::Log.error("Creating Errplane exception report")

      excep = run_status.exception
      setup_errplane
      Errplane.transmit(excep, errplane_params)
    end
  end

  def ignore_exception?(exception)
    ignore.any? do |ignore_case|
      ignore_case[:class] == exception.class.name && (!ignore_case.key?(:message) || !!ignore_case[:message].match(exception.message))
    end
  end

  def errplane_params
    {
      :notifier_name    => "Chef Errplane Notifier",
      :notifier_version => Errplane::VERSION,
      :notifier_url     => "https://github.com/errplane/gem",
      :component        => run_status.node.name,
      :url              => nil,
      :environment      => @environment,
      :params           => {
        :start_time   => run_status.start_time,
        :end_time     => run_status.end_time,
        :elapsed_time => run_status.elapsed_time,
        :run_list     => run_status.node.run_list.to_s
      }
    }.merge(options)
  end

  def setup_errplane
    raise ArgumentError.new("You must specify Errplane api key") unless api_key    
    Errplane.configure do |config|
      config.api_key = api_key
      config.application_id = "chef"
      config.application_name = "chef"
      # config.syslogd_port = "4445"
      config.logger = Chef::Log
      #config.logger = Logger.new(STDOUT)
      config.debug = false
      config.rails_environment = @environment
    end
  end
end