Errplane.configure(true) do |config|
  config.logger               ||= (defined?(logger) ? logger : ENV['rack.logger'])
  config.framework              = "Sinatra"
  config.framework_version      = ::Sinatra::VERSION

  if defined?(settings)
    config.rails_environment  ||= settings.environment
    config.application_root   ||= settings.root
  end
end

def handle_exception(e)
  request_data = {
    :request_url => request.env["REQUEST_URI"],
    :user_agent => request.env["HTTP_USER_AGENT"],
    :params => params["rack.request.query_hash"],
    :action => params["REQUEST_PATH"],
    :session => (defined?(session) ? session : params["rack.session"]) || {}
  }

  Errplane.transmit_unless_ignorable(e, request_data)
  raise e
end

if defined?(error)
  error { handle_exception(request.env['sinatra.error']) }
elsif defined?(Sinatra::Base)
  class Sinatra::Base
    error { handle_exception(request.env['sinatra.error']) }
  end
end
