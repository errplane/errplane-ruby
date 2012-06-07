require File.dirname(__FILE__) + "/integration_helper"

feature "exception handling" do
  describe "in an action that raises an exception" do
    scenario "should make an HTTP call to the API" do
      stub_request(:post, "#{Errplane::API_HOST}/exceptions").to_return(status: 200)

      lambda { visit new_widget_path }.should raise_error

      assert_requested :post, "#{Errplane::API_HOST}/api/v1/applications/#{Errplane.configuration.application_id}/exceptions/test?api_key=f123-e456-d789c012"
    end
  end

  describe "in an action that does not raise an exception" do
    scenario "should not make an HTTP call to the API" do
      lambda { visit widgets_path }.should_not raise_error

      assert_not_requested :post, "#{Errplane::API_HOST}/api/v1/applications/#{Errplane.configuration.application_id}/exceptions/test?api_key=f123-e456-d789c012"
    end
  end
end
