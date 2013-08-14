module Errplane
  class Api
    include Errplane::Logger

    attr_reader :last_response

    POST_RETRIES = 5
    READ_TIMEOUT = 3
    OPEN_TIMEOUT = 3

    HTTP_ERRORS = [ EOFError,
                    Errno::ECONNREFUSED,
                    Errno::ECONNRESET,
                    Errno::EINVAL,
                    Net::HTTPBadResponse,
                    Net::HTTPHeaderSyntaxError,
                    Net::ProtocolError,
                    Timeout::Error ].freeze

    def post(data)
      https = initialize_secure_connection
      retry_count = POST_RETRIES
      log :debug, "POSTing to #{url}"

      response = begin
                   log :debug, "POSTing data:\n#{data.to_json}"
                   https.post(url, data.to_json)
                 rescue *HTTP_ERRORS => e
                   log :error, "HTTP error contacting API! #{e.class}: #{e.message}"
                   retry_count -= 1
                   unless retry_count.zero?
                     log :info, "Retrying failed POST..."
                     sleep 1
                     retry
                   end
                   log :info, "Unable to POST after #{POST_RETRIES} attempts. Aborting!"
                 end

      if response.is_a?(Net::HTTPSuccess)
        log :info, "POST Succeeded: #{response.inspect}"
      else
        log :error, "POST Failed: #{response.inspect}"
      end

      @last_response = response
    end

    def send(data, operator="r")
      packet = {
        :d => Errplane.configuration.database_name,
        :a => Errplane.configuration.api_key.to_s,
        :o => operator,
        :w => [data]
      }

      log :debug, "Sending UDP Packet: #{packet.to_json}"

      begin
        udp_socket.send packet.to_json, 0, Errplane.configuration.api_udp_host, Errplane.configuration.api_udp_port
      rescue => e
        log :error, "Failed to send data via UDP. Check your network settings and available file descriptors. #{e.class}: #{e.message}"
      end
    end

    private
    def udp_socket
      Thread.current[:errplane_udp_socket] ||= UDPSocket.new
    end

    def url
      "/databases/" \
      + Errplane.configuration.database_name \
      + "/points?api_key=" \
      + Errplane.configuration.api_key.to_s
    end

    def initialize_secure_connection
      connection = Net::HTTP.new(Errplane.configuration.api_http_write_host, 443)
      connection.use_ssl = true
      connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      connection.read_timeout = READ_TIMEOUT
      connection.open_timeout = OPEN_TIMEOUT
      connection
    end
  end
end
