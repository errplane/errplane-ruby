module Errplane
  class Transmitter
    include Errplane::Logger

    HTTP_ERRORS = [ EOFError,
                    Errno::ECONNREFUSED,
                    Errno::ECONNRESET,
                    Errno::EINVAL,
                    Net::HTTPBadResponse,
                    Net::HTTPHeaderSyntaxError,
                    Net::ProtocolError,
                    Timeout::Error ].freeze

    def initialize(params = {})
    end

    def relay(black_box, deployment = false)
      http = initialize_http_connection
      data = black_box.to_json
      response = begin
                   url = "/api/v1/applications/#{Errplane.configuration.application_id}/exceptions/#{Errplane.configuration.rails_environment}#{"/deploy" if deployment}?api_key=#{Errplane.configuration.api_key}"
                   log :info, "URL: #{url}"
                   log :info, "Data: #{data.inspect}"
                   http.post(url, data)
                 rescue *HTTP_ERRORS => e
                   log :error, "Error contacting Errplane API! #{e.class}: #{e.message}"
                 end

      if response == Net::HTTPSuccess
        log :info, "Request Succeeded: #{response.inspect}"
      else
        log :error, "Request Failed: #{response.inspect}"
      end
    end

    private
    def initialize_http_connection
      connection = Net::HTTP.new(Errplane.configuration.api_host, "80")
    end
  end
end
