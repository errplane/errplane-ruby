module Errplane
  module Rails
    module Instrumentation
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def instrument(methods = [])
          methods = [methods] unless methods.is_a?(Array)
          methods.each do |method|
            ::Rails.logger.debug "OVERRIDING METHOD: #{method}"

            class_eval <<-EVAL_METHOD
              def #{method}_with_instrumentation
                Errplane.report(\"instrumentation/#{self.class}##{method}\")
                #{method}_without_instrumentation
              end
            EVAL_METHOD

            alias_method "#{method}_without_instrumentation", method
            alias_method method, "#{method}_with_instrumentation"
          end
        end
      end
    end
  end
end
