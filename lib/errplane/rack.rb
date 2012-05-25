module Errplane
  class Rack
    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        response = @app.call(env)
      rescue Exception => e
        Errplane.transmit_to_api(e)
        raise
      end

      response
    end
  end
end
