require 'spec_helper'

describe Errplane::Configuration do
  before do
    @configuration = Errplane::Configuration.new
  end

  describe "#ignore_user_agent?" do
    it "should be true for user agents that have been set as ignorable" do
      @configuration.ignored_user_agents = %w{Googlebot}
      @configuration.ignore_user_agent?("Googlebot/2.1").should be_true
    end

    it "should be false for user agents that have not been set as ignorable" do
      @configuration.ignored_user_agents = %w{Googlebot}
      @configuration.ignore_user_agent?("Mozilla/5.0").should be_false
    end

    it "should be false if the ignored user agents list is empty" do
      @configuration.ignored_user_agents = []
      @configuration.ignore_user_agent?("Googlebot/2.1").should be_false
    end

    it "should be false if the ignored user agents list is inadvertently set to nil" do
      @configuration.ignored_user_agents = nil
      @configuration.ignore_user_agent?("Googlebot/2.1").should be_false
    end
  end
end
