module Errplane
  module Rails
    module Middleware
      module HijackRenderException
        def self.included(base)
          base.send(:alias_method_chain, :render_exception, :errplane)
        end

        def render_exception_with_errplane(env, e)
          controller = env['action_controller.instance']
          Errplane.transmit_unless_ignorable(e, env)
          render_exception_without_errplane(env, e)
        end
      end
    end
  end
end

