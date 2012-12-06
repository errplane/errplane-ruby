require 'spec_helper'

describe Errplane::Backtrace do
  before do
    @raw_backtrace = [
      "/var/www/current/app/models/foo.rb:10:in `bar'",
      "/var/www/current/app/models/foo.rb:19:in `baz'",
      "/var/www/current/app/models/foo.rb:32:in `<main>'"
    ]

    @backtrace = Errplane::Backtrace.new(@raw_backtrace)
  end

  it "should accept an exception into the initializer" do
    @backtrace.lines.should_not be_empty
    @backtrace.lines.count.should == 3
  end

  it "should correctly parse lines into their elements" do
    line = @backtrace.lines.first

    line.file.should == "/var/www/current/app/models/foo.rb"
    line.number.should == "10"
    line.method.should == "bar"
  end

  describe "#to_a" do
    it "should return an array of lines" do
      @backtrace.to_a.is_a?(Array).should be_true
    end
  end

  context "nil backtrace" do
    before do
      # Exception.new.backtrace == nil
      @raw_backtrace = nil

      @backtrace = Errplane::Backtrace.new(@raw_backtrace)
    end

    it "should accept an exception into the initializer" do
      @backtrace.lines.should be_empty
      @backtrace.lines.count.should == 0
    end

    describe "#to_a" do
      it "should return an array of lines" do
        @backtrace.to_a.is_a?(Array).should be_true
      end
    end

  end

  describe "backtrace filters" do
    before do
      Errplane.configure do |config|
        config.application_root = "/var/www/current"
      end
    end

    it "should apply a single default backtrace filter correctly" do
      filtered_backtrace = Errplane::Backtrace.new(@raw_backtrace)

      line = filtered_backtrace.lines.first
      line.file.should == "[APP_ROOT]/app/models/foo.rb"
    end

    it "should all default backtrace filters correctly" do
      extended_backtrace = @raw_backtrace.dup
      extended_backtrace << "#{Gem.path.first}/lib/foo_gem.rb:1:in `blah'"

      filtered_backtrace = Errplane::Backtrace.new(extended_backtrace)
      filtered_backtrace.lines.first.file.should == "[APP_ROOT]/app/models/foo.rb"
      filtered_backtrace.lines.last.file.should == "[GEM_ROOT]/lib/foo_gem.rb"
    end

    it "should allow the addition of custom backtrace filters" do
      Errplane.configure do |config|
        config.backtrace_filters << lambda { |line| line.gsub(/foo/, "F00") }
      end

      filtered_backtrace = Errplane::Backtrace.new(@raw_backtrace)

      line = filtered_backtrace.lines.first
      line.file.should == "[APP_ROOT]/app/models/F00.rb"
    end
  end
end

