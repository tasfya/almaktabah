module Api
  module V1
    class AuthenticationController < ApiController
      # POST /api/v1/login
      def login
        user = User.find_by(email: login_params[:email])

        if user&.valid_password?(login_params[:password])
          token = JsonWebToken.encode(user_id: user.id)
          render json: { token: token, user_id: user.id, email: user.email }, status: :ok
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      private

      def login_params
        params.require(:user).permit(:email, :password)
      end
    end
  end
end
