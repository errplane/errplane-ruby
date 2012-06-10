require 'spec_helper'

describe Errplane do
  describe ".ignorable_exception?" do
    it "should be true for exception types specified in the configuration" do
      class DummyException < Exception; end
      exception = DummyException.new

      Errplane.configure do |config|
        config.ignored_exceptions << 'DummyException'
      end

      Errplane.ignorable_exception?(exception).should be_true
    end

    it "should be true for exception types specified in the configuration" do
      exception = ActionController::RoutingError.new("foo")
      Errplane.ignorable_exception?(exception).should be_true
    end

    it "should be false for valid exceptions" do
      exception = ZeroDivisionError.new
      Errplane.ignorable_exception?(exception).should be_false
    end
  end
end
