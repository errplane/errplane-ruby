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

    begin
      puts "Contacting Errplane API"
      application_name = "ApplicationName"
      api_key = options[:api_key]

      connection = Net::HTTP.new("errplane.com", 443)
      connection.use_ssl = true
      connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      url = "/api/v1/applications?api_key=#{api_key}&name=#{application_name}"
      response = connection.post(url, nil)

      @application = JSON.parse(response.body)

      unless response.is_a?(Net::HTTPSuccess)
        raise "The Errplane API returned an error: #{response.inspect}"
      end
    rescue => e
      puts "We ran into a problem creating your application via the API!"
      puts "If this issue persists, contact us at support@errplane.com with the following details:"
      puts "API Key: #{e.class}: #{options[:api_key]}"
      puts "#{e.class}: #{e.message}"
    end

    record do |m|
      m.template "initializer.rb", "config/initializers/errplane.rb",
        :assigns => {
          :application_id => options[:application_id] || @application["key"] || secure_random.hex(4),
          :api_key => options[:api_key]
        }
    end
  end

  def secure_random
    defined?(SecureRandom) ? SecureRandom : ActiveSupport::SecureRandom
  end
end
