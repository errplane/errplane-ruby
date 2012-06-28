Errplane.configure(true) do |config|
  config.logger                ||= logger
  config.rails_environment     ||= settings.environment
  config.application_root            ||= settings.root
  config.framework               = "Sinatra"
  config.framework_version       = ::Sinatra::VERSION
end

error do
  Errplane.transmit_unless_ignorable(request.env['sinatra.error'], request.env)
  raise request.env['sinatra.error']
end
