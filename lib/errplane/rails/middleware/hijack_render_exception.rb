module Errplane
  module Rails
    module Middleware
      module HijackRenderException
        def self.included(base)
          base.send(:alias_method_chain, :render_exception, :errplane)
        end

        def render_exception_with_errplane(env, e)
          controller = env["action_controller.instance"]
          Errplane.configuration.logger.info("Controller: #{controller}")
          request_data = controller.try(:errplane_request_data) || {}
          Errplane.configuration.logger.info("Request Data: #{request_data}")
          unless Errplane.configuration.ignore_user_agent?(request_data[:user_agent])
            Errplane.transmit_unless_ignorable(e, request_data)
          end
          render_exception_without_errplane(env, e)
        end
      end
    end
  end
end

