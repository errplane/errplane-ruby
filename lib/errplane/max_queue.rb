require "thread"

module Errplane
  class MaxQueue < Queue
    attr_reader :max

    def initialize(max = 10_000)
      raise ArgumentError, "queue size must be positive" unless max > 0
      @max = max
      super()
    end

    def push(obj)
      super if @que.length < @max
    end
  end
end
