module Errplane
  class Transmitter
    include Errplane::Logger

    attr_reader :last_response

    HTTP_ERRORS = [ EOFError,
                    Errno::ECONNREFUSED,
                    Errno::ECONNRESET,
                    Errno::EINVAL,
                    Net::HTTPBadResponse,
                    Net::HTTPHeaderSyntaxError,
                    Net::ProtocolError,
                    Timeout::Error ].freeze

    def initialize(params = {})
      @last_response = nil
    end

    def enqueue(black_box)
      log :info, "Adding exception to the queue."
      url = "/api/v1/applications/#{Errplane.configuration.application_id}/exceptions/#{Errplane.configuration.rails_environment}?api_key=#{Errplane.configuration.api_key}"
      exception = { :data => black_box.to_json,
                    :url => url,
                    :source => "exception" }

      Errplane.queue.push(exception)
    end

    def deliver(data, url)
      http = initialize_http_connection
      response = begin
                   log :info, "URL: #{url}"
                   log :info, "Data: #{data.inspect}"
                   http.post(url, data)
                 rescue *HTTP_ERRORS => e
                   log :error, "HTTP error contacting Errplane API! #{e.class}: #{e.message}"
                 end

      @last_response = response
      if response.is_a?(Net::HTTPSuccess)
        log :info, "Exception POST Succeeded: #{response.inspect}"
      else
        log :error, "Exception POST Failed: #{response.inspect}"
      end
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
                   log :error, "HTTP error contacting Errplane API! #{e.class}: #{e.message}"
                 end

      @last_response = response
      if response.is_a?(Net::HTTPSuccess)
        log :info, "Request Succeeded: #{response.inspect}"
      else
        log :error, "Request Failed: #{response.inspect}"
      end
    end

    private
    def initialize_http_connection
      connection = Net::HTTP.new("api.errplane.com", 443)
      connection.use_ssl = true
      connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      connection
    end
  end
end
