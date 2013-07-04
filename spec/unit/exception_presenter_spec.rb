require 'spec_helper'

describe Errplane::ExceptionPresenter do
  before do
    begin
      1/0
    rescue Exception => e
      @exception = e
    end
  end

  describe ".new" do
    it "should create a new ExceptionPresenter" do
      exception_presenter = Errplane::ExceptionPresenter.new(@exception)
      exception_presenter.should be_a(Errplane::ExceptionPresenter)
    end

    it "should accept an exception as a parameter" do
      exception_presenter = Errplane::ExceptionPresenter.new(@exception)
      exception_presenter.should_not be_nil
    end
  end

  # describe "#to_json" do
    # it "should return a JSON string" do
      # exception_presenter = Errplane::ExceptionPresenter.new(@exception)
      # json = JSON.parse(exception_presenter.to_json)

      # json["message"].should == "divided by 0"
      # json["time"].should_not be_nil
      # json["backtrace"].should_not be_nil
    # end

    # it "should include a custom hash if defined in the errplane config" do
      # Errplane.configure do |config|
        # config.define_custom_exception_data do |exception_presenter|
          # if exception_presenter.exception.class ==  ZeroDivisionError
            # exception_presenter.hash = "some_hash"
            # exception_presenter.custom_data[:extra_info] = "blah"
          # end
        # end
      # end

      # exception_presenter = Errplane::ExceptionPresenter.new(@exception)
      # json = JSON.parse(exception_presenter.to_json)
      # json["hash"].should == "some_hash"
      # json["custom_data"]["extra_info"].should == "blah"
    # end

    # describe "environment variables" do
      # it "should be filtered based on the contents of environment_variable_filters" do
        # Errplane.configure do |config|
          # config.environment_variable_filters = [/password/i]
        # end

        # exception_presenter = Errplane::ExceptionPresenter.new(
          # :exception => @exception,
          # :environment_variables => {
            # "IMPORTANT_PASSWORD" => "sesame",
            # "EDITOR" => "vim"
        # })

        # json = JSON.parse(exception_presenter.to_json)
        # json["environment_variables"].size.should == 1
        # json["environment_variables"].should == {"EDITOR" => "vim"}
      # end
    # end
  # end
end
