module Errplane
  class MaxQueue < Queue
    attr_accessor :max_depth

    def initialize(max_depth = 10_000)
      @max_depth = max_depth
      super()
    end

    def push_or_discard(data)
      push(data) if size < @max_depth
    end
  end
end
