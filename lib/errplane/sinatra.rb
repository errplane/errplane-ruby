Errplane.configure(true) do |config|
  config.logger                ||= ENV['rack.logger']
  config.rails_environment     ||= settings.environment if defined?(settings)
  config.application_root            ||= settings.root if defined?(settings)
  config.framework               = "Sinatra"
  config.framework_version       = ::Sinatra::VERSION
end

if defined?(error)
	error do
	  Errplane.transmit_unless_ignorable(request.env['sinatra.error'], request.env)
	  raise request.env['sinatra.error']
	end
end