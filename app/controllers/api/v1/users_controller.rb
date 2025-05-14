module Api
  module V1
    class UsersController < ApplicationController
      skip_before_action :verify_authenticity_token, only: [ :create ]

      # POST /api/v1/signup
      def create
        user = User.new(user_params)

        if user.save
          token = JsonWebToken.encode(user_id: user.id)
          render json: {
            token: token,
            user: ActiveModelSerializers::SerializableResource.new(user)
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def me
        if current_user
          render json: {
            user: ActiveModelSerializers::SerializableResource.new(current_user)
          }, status: :ok
        else
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end

      private

      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation)
      end
    end
  end
end
