module Errplane
  class MaxQueue < SizedQueue
    def push(obj)
      super if @que.length < @max
    end
  end
end
