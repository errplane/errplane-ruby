# Errplane.configure(true) do |config|
  # config.logger            ||= ::Sinatra.logger
  # config.rails_environment ||= ::Sinatra.environment
  # config.rails_root        ||= ::Sinatra.root
  # config.framework           = "Sinatra"
  # config.framework_version   = ::Sinatra::VERSION
# end

error do
  Errplane.transmit_to_api(request.env['sinatra.error'], request.env)
  raise request.env['sinatra.error']
end
