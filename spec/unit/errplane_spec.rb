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

  describe 'rescue' do

    it "should transmit an exception when passed" do
      Errplane.configure do |config|
        config.ignored_environments = %w{development}
      end

      stub_request(:post, "#{Errplane.configuration.api_host}/api/v1/applications/#{Errplane.configuration.application_id}/exceptions/test?api_key=f123-e456-d789c012").to_return(:status => 200)
      Errplane.rescue do
        raise ArgumentError.new('wrong')
      end
      assert_requested :post, "#{Errplane.configuration.api_host}/api/v1/applications/#{Errplane.configuration.application_id}/exceptions/test?api_key=f123-e456-d789c012"
    end

    it "should also raise the exception when in an ignored environment" do
      Errplane.configure do |config|
        config.ignored_environments = %w{development test}
      end
      expect {
        Errplane.rescue do
          raise ArgumentError.new('wrong')
        end
      }.to raise_error(ArgumentError)
    end
  end

  describe "rescue_and_reraise" do
    before do
      Errplane.configure do |config|
        config.ignored_environments = %w{development}
      end
    end

    it "should transmit an exception when passed" do
      stub_request(:post, "#{Errplane.configuration.api_host}/api/v1/applications/#{Errplane.configuration.application_id}/exceptions/test?api_key=f123-e456-d789c012").to_return(:status => 200)
      expect {
        Errplane.rescue_and_reraise { raise ArgumentError.new('wrong') }
      }.to raise_error(ArgumentError)
      assert_requested :post, "#{Errplane.configuration.api_host}/api/v1/applications/#{Errplane.configuration.application_id}/exceptions/test?api_key=f123-e456-d789c012"
    end
  end

end
