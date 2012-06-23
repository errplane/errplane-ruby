require 'rails/generators'

class ErrplaneGenerator < Rails::Generators::Base
  desc "Description:\n  This creates a Rails initializer for Errplane."

  source_root File.expand_path('../templates', __FILE__)
  argument :api_key,
    required: true,
    type: :string,
    description: "API key for your Errplane organization"
  argument :application_id,
    required: false,
    default: SecureRandom.hex(4),
    type: :string,
    description: "Identifier for this application (Leave blank and a new one will be generated for you)"

  def copy_initializer_file
    template "initializer.rb", "config/initializers/errplane.rb"
  end

  def install
  end
end
