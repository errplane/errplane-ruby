require 'rails/generators'

class ErrplaneGenerator < Rails::Generators::Base
  desc "Description:\n  This creates a Rails initializer for Errplane."

  application_name = Rails.application.class.parent_name
  api_key = ARGV.last
  http = Net::HTTP.new("localhost", "3000")
  url = "/api/v1/applications?api_key=#{api_key}&name=#{application_name}"
  response = http.post(url, nil)
  @application = JSON.parse(response.body)

  source_root File.expand_path('../templates', __FILE__)
  argument :api_key,
    :required => true,
    :type => :string,
    :description => "API key for your Errplane organization"
  argument :application_id,
    :required => false,
    :default => @application["key"],
    :type => :string,
    :description => "Identifier for this application (Leave blank and a new one will be generated for you)"

  def copy_initializer_file
    template "initializer.rb", "config/initializers/errplane.rb"
  end

  def install
  end
end
