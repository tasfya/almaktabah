# frozen_string_literal: true

module Api
  class BaseController < ActionController::API
    before_action :authenticate_api_token!

    private

    def authenticate_api_token!
      token = request.headers["Authorization"]&.split("Bearer ")&.last
      expected_token = Rails.application.credentials.dig(:api, :download_token) ||
                       ENV["YOUTUBE_DOWNLOAD_API_TOKEN"]

      unless expected_token.present? && ActiveSupport::SecurityUtils.secure_compare(token.to_s, expected_token)
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end
  end
end
