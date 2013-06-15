module Errplane
  class Rack
    def initialize(app)
      @app = app
    end

    def call(env)
      dup._call(env)
    end

    def _call(env)
      begin
        status, headers, body = @app.call(env)
      rescue => e
        Errplane.transmit_unless_ignorable(e, env)
        raise(e)
      ensure
        _body = []
        body.each { |line| _body << line } unless body.nil?
        body.close if body.respond_to?(:close)
      end

      [status, headers, _body]
    end
  end
end
