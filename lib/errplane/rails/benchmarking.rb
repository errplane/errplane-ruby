require 'benchmark'

module Errplane
  module Rails
    module Benchmarking
      def self.included(base)
        base.send(:alias_method_chain, :perform_action, :instrumentation)
        base.send(:alias_method_chain, :view_runtime, :instrumentation)
        base.send(:alias_method_chain, :active_record_runtime, :instrumentation)
      end

      private
      def perform_action_with_instrumentation
        ms = Benchmark.ms { perform_action_without_instrumentation }
        Errplane.report "controllers/#{params[:controller]}/#{params[:action]}", :value => ms.ceil
      end

      def view_runtime_with_instrumentation
        runtime = view_runtime_without_instrumentation
        Errplane.report "views", :value => runtime.split.last.to_f.ceil
        runtime
      end

      def active_record_runtime_with_instrumentation
        runtime = active_record_runtime_without_instrumentation
        Errplane.report "db", :value => runtime.split.last.to_f.ceil
        runtime
      end
    end
  end
end
