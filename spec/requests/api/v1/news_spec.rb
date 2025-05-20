require 'rails_helper'

RSpec.describe "Api::V1::News", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/news"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /recent" do
    it "returns http success" do
      get "/api/news/recent"
      expect(response).to have_http_status(:success)
    end
  end
end
