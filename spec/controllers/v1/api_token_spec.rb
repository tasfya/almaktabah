require 'rails_helper'

RSpec.describe "API Token Authentication", type: :request do
  describe "expired tokens" do
    let(:user) { create(:user) }
    let(:expired_token) { create(:api_token, :expired, user: user) }

    it "rejects expired tokens" do
      get '/api/fatwas', headers: { 'X-API-Token' => expired_token.token }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to include('error')
      expect(json_response['error']).to eq('Unauthorized')
    end
  end

  describe "inactive tokens" do
    let(:user) { create(:user) }
    let(:inactive_token) { create(:api_token, :inactive, user: user) }

    it "rejects inactive tokens" do
      get '/api/fatwas', headers: { 'X-API-Token' => inactive_token.token }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to include('error')
      expect(json_response['error']).to eq('Unauthorized')
    end
  end

  describe "query parameter token" do
    let(:user) { create(:user) }
    let(:token) { create(:api_token, user: user) }

    it "accepts valid token in query parameter" do
      get "/api/fatwas?api_token=#{token.token}"

      expect(response).to have_http_status(:ok)
    end
  end
end
