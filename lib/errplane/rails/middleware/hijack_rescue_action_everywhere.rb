module Errplane
  module Rails
    module Middleware
      module HijackRescueActionEverywhere
        def self.included(base)
          base.send(:alias_method_chain, :rescue_action_in_public, :errplane)
          base.send(:alias_method_chain, :rescue_action_locally, :errplane)
        end

        private
        def rescue_action_in_public_with_errplane(e)
          handle_exception(e)
          rescue_action_in_public_without_errplane(e)
        end

        def rescue_action_locally_with_errplane(e)
          handle_exception(e)
          rescue_action_locally_without_errplane(e)
        end

        def handle_exception(e)
          request_data = errplane_request_data || {}

          unless Errplane.configuration.ignore_user_agent?(request_data[:user_agent])
            Errplane.report_exception_unless_ignorable(e, request_data)
          end
        end
      end
    end
  end
end

