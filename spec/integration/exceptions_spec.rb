require File.expand_path(File.dirname(__FILE__) + "/integration_helper")

describe "exception handling" do
  before do
    Errplane.configure do |config|
      config.ignored_environments = %w{development}
      # config.debug = true
      # config.logger = Logger.new(STDOUT)
    end

    FakeWeb.last_request = nil
    FakeWeb.clean_registry
    @request_path = "/api/v1/applications/#{Errplane.configuration.application_id}/exceptions/test?api_key=f123-e456-d789c012"
    @request_url = "http://api.errplane.com#{@request_path}"
    FakeWeb.register_uri(:post, @request_url, :body => "", :status => ["200", "OK"])
  end

  describe "in an action that raises an exception" do
    it "should make an HTTP call to the API" do
      get "/widgets/new"
      FakeWeb.last_request.method.should == "POST"
      FakeWeb.last_request.path.should == @request_path
    end
  end

  describe "in an action that does not raise an exception" do
    it "should not make an HTTP call to the API" do
      get "/widgets"
      FakeWeb.last_request.should be_nil
    end
  end
end

