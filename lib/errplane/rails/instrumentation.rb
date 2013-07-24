module Errplane
  module Rails
    module Instrumentation
      def benchmark_for_instrumentation
        start = Time.now
        yield

        unless Errplane.configuration.ignore_current_environment?
          elapsed = ((Time.now - start) * 1000).ceil
          dimensions = { :method => "#{controller_name}##{action_name}", :server => Socket.gethostname }
          Errplane.aggregate "instrumentation", :value => elapsed, :dimensions => dimensions
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def instrument(methods = [])
          methods = [methods] unless methods.is_a?(Array)
          around_filter :benchmark_for_instrumentation, :only => methods
        end
      end
    end
  end
end
