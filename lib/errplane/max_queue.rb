require "thread"

module Errplane
  class MaxQueue < Queue
    attr_reader :max

    def initialize(max = 10_000)
      raise ArgumentError, "queue size must be positive" unless max > 0
      @max = max
      Errplane::Worker.spawn_threads if Errplane::Worker.current_thread_count.zero?
      super()
    end

    def push(obj)
      super if length < @max
    end
  end
end
