module Api
  module V1
    class ApiController < ActionController::Base
      include Api::ErrorHandling

      before_action :authenticate_request

      private

      def authenticate_request
        # Try JWT token authentication first (for user-specific operations)
        auth_header = request.headers["Authorization"]
        if auth_header && auth_header.start_with?("Bearer ")
          token = auth_header.split(" ").last
          decoded = JsonWebToken.decode(token)
          if decoded
            @current_user = User.find(decoded[:user_id])
            return
          end
        end

        # Try API token authentication
        api_token = request.headers["X-API-Token"] || params[:api_token]
        if api_token.present?
          token = ApiToken.active.find_by(token: api_token)
          return if token
        end

        # No valid authentication method found
        render json: { error: "Unauthorized" }, status: :unauthorized
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end
  end
end
