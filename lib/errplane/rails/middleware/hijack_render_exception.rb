module Errplane
  module Rails
    module Middleware
      module HijackRenderException
        def self.included(base)
          base.send(:alias_method_chain,:render_exception,:errplane)
        end

        def render_exception_with_errplane(env,exception)
          Errplane.transmit_to_api(exception)
          render_exception_without_errplane(env,exception)
        end
      end
    end
  end
end

