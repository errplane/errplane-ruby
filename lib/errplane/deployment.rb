module Errplane
  class Deployment
    def announce
      http = Net::HTTP.new(Errplane.configuration.api_host, "80")
      url = "/api/v1/deployments"
      data = {}
      response = begin
                   http.post(url, data)
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
  end
end
