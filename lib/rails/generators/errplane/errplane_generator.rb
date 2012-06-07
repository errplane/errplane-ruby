require 'rails/generators'

class ErrplaneGenerator < Rails::Generators::Base
  desc "Description:\n  This creates a Rails initializer for Errplane."

  source_root File.expand_path('../templates', __FILE__)
  argument :api_key,
    required: false,
    type: :string,
    description: "API Key for your Errplane Organization"
  argument :application_id,
    required: false,
    default: lambda { Time.now.to_s },
    type: :string,
    description: "API Key for your Errplane Organization"

  def copy_initializer_file
    template "initializer.rb", "config/initializers/errplane.rb"
  end

  def install
  end
end
