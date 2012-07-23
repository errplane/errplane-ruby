require 'spec_helper'

describe Errplane::BlackBox do
  before do
    begin
      1/0
    rescue Exception => e
      @exception = e
    end
  end

  describe ".new" do
    it "should create a new BlackBox" do
      black_box = Errplane::BlackBox.new
    end

    it "should accept an exception as a parameter" do

      black_box = Errplane::BlackBox.new(:exception => @exception)
      black_box.should_not be_nil
    end
  end

  describe "#to_json" do
    it "should return a JSON string" do
      black_box = Errplane::BlackBox.new(:exception => @exception)
      json = JSON.parse(black_box.to_json)

      json["message"].should == "divided by 0"
      json["time"].should_not be_nil
      json["backtrace"].should_not be_nil
    end

    it "should include a custom hash if defined in the errplane config" do
      Errplane.configure do |config|
        config.define_custom_exception_data do |black_box|
          if black_box.exception.class ==  ZeroDivisionError
            black_box.hash = "some_hash"
            black_box.custom_data[:extra_info] = "blah"
          end
        end
      end

      black_box = Errplane::BlackBox.new(:exception => @exception)
      json = JSON.parse(black_box.to_json)
      json["hash"].should == "some_hash"
      json["custom_data"]["extra_info"].should == "blah"
    end
  end
end
