module Errplane
	def self.get_logger
		if( defined?(logger))
			logger 
		else
			ENV['rack.logger'] 
		end
	end
end

Errplane.configure(true) do |config|
  config.logger                ||= Errplane::get_logger
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
elsif defined?(Sinatra::Base)
	class Sinatra::Base
		error do
		  Errplane.transmit_unless_ignorable(request.env['sinatra.error'], request.env)
		  raise request.env['sinatra.error']
		end	
	end
end


