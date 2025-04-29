module Api
  module V1
    class ApiController < ActionController::Base
      include Api::ErrorHandling
      
      before_action :authenticate_request
      
      private
      
      def authenticate_request
        header = request.headers["Authorization"]
        header = header.split(" ").last if header
        
        decoded = JsonWebToken.decode(header)
        if decoded
          @current_user = User.find(decoded[:user_id])
        else
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end
  end
end