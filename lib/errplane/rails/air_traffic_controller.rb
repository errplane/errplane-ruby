module Errplane
  module Rails
    module AirTrafficController
      def errplane_request_data
        unfiltered_params = params.to_hash
        if respond_to?(:filter_parameters)
          filtered_params = filter_parameters(unfiltered_params)
        elsif defined? request.filtered_parameters
          filtered_params = request.filtered_parameters
        else
          filtered_params = unfiltered_params.except(:password, :password_confirmation)
        end

        {
          :params => filtered_params,
          :session_data => errplane_session_data,
          :controller => params[:controller],
          :action => params[:action],
          :request_url => errplane_request_url,
          :user_agent => request.env["HTTP_USER_AGENT"],
          :remote_ip => request.remote_ip,
          :referer => request.referer,
          :current_user => (current_user rescue nil)
        }
      end

      private
      def errplane_session_data
        session.respond_to?(:to_hash) ? session.to_hash : session.data
      end

      def errplane_request_url
        url = "#{request.protocol}#{request.host}"
        url << ":#{request.port}" unless [80, 443].include?(request.port)
        url << request.fullpath
      end
    end
  end
end
