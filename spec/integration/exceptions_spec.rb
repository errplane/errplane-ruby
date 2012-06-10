require File.dirname(__FILE__) + "/integration_helper"

feature "exception handling" do
  before do
    Errplane.configure do |config|
      config.ignored_environments = %w{development}
    end
  end

  describe "in an action that raises an exception" do
    scenario "should make an HTTP call to the API" do
      stub_request(:post, "#{Errplane.configuration.api_host}/exceptions").to_return(status: 200)

      lambda { visit new_widget_path }.should raise_error

      assert_requested :post, "#{Errplane.configuration.api_host}/api/v1/applications/#{Errplane.configuration.application_id}/exceptions/test?api_key=f123-e456-d789c012"
    end
  end

  describe "in an action that does not raise an exception" do
    scenario "should not make an HTTP call to the API" do
      lambda { visit widgets_path }.should_not raise_error

      assert_not_requested :post, "#{Errplane.configuration.api_host}/api/v1/applications/#{Errplane.configuration.application_id}/exceptions/test?api_key=f123-e456-d789c012"
    end
  end
end
