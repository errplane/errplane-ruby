module Errplane
  module Rails
    module Instrumentation
      def benchmark_for_instrumentation
        start = Time.now
        yield
        elapsed = ((Time.now - start) * 1000).ceil
        dimensions = { :method => "#{controller_name}##{action_name}", :server => Socket.gethostname }
        Errplane.rollup "instrumentation", :value => elapsed, :dimensions => dimensions
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
