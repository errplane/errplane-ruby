module Errplane
  class Transmitter
    def initialize(params = {})
    end

    def relay(black_box, deployment = false)
      http = initialize_http_connection
      data = black_box.to_json
      response = begin
                   url = "/api/v1/applications/#{Errplane.configuration.application_id}/exceptions/#{Errplane.configuration.rails_environment}#{"/deploy" if deployment}?api_key=#{Errplane.configuration.api_key}"
                   Errplane.configuration.logger.info("\nURL: #{url}") if Errplane.configuration.debug?
                   Errplane.configuration.logger.info("\nData: #{data.inspect}") if Errplane.configuration.debug?
                   response = http.post(url, data)
                   Errplane.configuration.logger.info("\nException Response: #{response.inspect}") if Errplane.configuration.debug?
                   response
                 rescue Exception => e
                   # e
                 end

      case response
      when Net::HTTPSuccess
        # Success
      else
        # Failure
      end
    end

    private
    def initialize_http_connection
      connection = Net::HTTP.new(Errplane.configuration.api_host, "80")
    end
  end
end
