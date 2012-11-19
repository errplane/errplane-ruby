class ErrplaneGenerator < Rails::Generator::Base
  def add_options!(option)
    option.on("-k", "--api-key=API_KEY", String, "API key for your Errplane organization") {|v| options[:api_key] = v}
    option.on("-a", "--application-id=APP_ID", String, "Your Errplane application id (optional)") {|v| options[:application_id] = v}
  end

  def manifest
    if options[:api_key].blank?
      puts "You must provide an API key using -k or --api-key."
      exit
    end
    record do |m|
      m.template "initializer.rb", "config/initializers/errplane.rb",
        :assigns => {
          :application_id => options[:application_id] || secure_random.hex(4),
          :api_key => options[:api_key]
        }
    end
  end

  def secure_random
    defined?(SecureRandom) ? SecureRandom : ActiveSupport::SecureRandom
  end
end
