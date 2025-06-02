require 'rails_helper'

# Helper module for API request specs
module ApiHelpers
  # Parse JSON response body
  def json_response
    JSON.parse(response.body)
  end

  # Generate and include API token in request headers
  def with_api_token
    @user ||= create(:user)
    @api_token ||= @user.create_api_token(purpose: 'Test API')
    { 'X-API-Token' => @api_token.token }
  end

  # Include user JWT token in request headers
  def with_user_token(user = nil)
    user ||= create(:user)
    token = JsonWebToken.encode(user_id: user.id)
    { 'Authorization' => "Bearer #{token}" }
  end
end

# Include helpers in RSpec
RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
