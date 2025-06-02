require 'rails_helper'

RSpec.describe "Api::V1::News", type: :request do
  let(:token) { create(:api_token) }
  describe "GET /index" do
    it "returns http success" do
      get "/api/news", params: { api_token: token.token }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /recent" do
    it "returns http success" do
      get "/api/news/recent", params: { api_token: token.token }
      expect(response).to have_http_status(:success)
    end
  end
end
