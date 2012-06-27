Errplane.configure(true) do |config|
  config.logger                ||= logger
  config.rails_environment     ||= settings.environment
  config.rails_root            ||= settings.root
  config.framework               = "Sinatra"
  config.framework_version       = ::Sinatra::VERSION
  config.language                = "Ruby"
  config.language_version        = "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"
  config.environment_variables   = ENV.to_hash
end

error do
  Errplane.transmit_unless_ignorable(request.env['sinatra.error'], request.env)
  raise request.env['sinatra.error']
end
