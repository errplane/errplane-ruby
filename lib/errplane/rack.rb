module Errplane
  class Rack
    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        response = @app.call(env)
      rescue => e
        Errplane.transmit_unless_ignorable(e, env)
        raise(e)
      end

      response
    end
  end
end
