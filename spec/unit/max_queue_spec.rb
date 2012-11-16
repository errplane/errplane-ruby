require 'spec_helper'

describe Errplane::MaxQueue do
  it "should inherit from Queue" do
    Errplane::MaxQueue.new.should be_a(Queue)
  end

  context "#new" do
    it "should allow max_depth to be set" do
      queue = Errplane::MaxQueue.new(500)
      queue.max_depth.should == 500
    end
  end

  context "#push_or_discard" do
    it "should allow an item to be added if the queue is not full" do
      queue = Errplane::MaxQueue.new(5)
      queue.size.should be_zero
      queue.push_or_discard(1)
      queue.size.should == 1
    end

    it "should not allow items to be added if the queue is full" do
      queue = Errplane::MaxQueue.new(5)
      queue.size.should be_zero
      5.times { |n| queue.push_or_discard(n) }
      queue.size.should == 5
      queue.push_or_discard(6)
      queue.size.should == 5
    end
  end
end
