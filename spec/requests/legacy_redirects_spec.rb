# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Legacy English path redirects", type: :request do
  let!(:domain) { create(:domain, host: "www.example.com") }

  before do
    host! "www.example.com"
  end

  describe "English index paths → Arabic equivalents" do
    it "redirects /lectures to Arabic path with 301" do
      get "/lectures"
      expect(response).to have_http_status(:moved_permanently)
      expect(response.location).to include(URI::DEFAULT_PARSER.escape(I18n.t("routes.lectures")))
    end

    it "redirects /fatwas to Arabic path with 301" do
      get "/fatwas"
      expect(response).to have_http_status(:moved_permanently)
      expect(response.location).to include(URI::DEFAULT_PARSER.escape(I18n.t("routes.fatwas")))
    end

    it "preserves query string on redirect" do
      get "/lectures?page=5&q=test"
      expect(response).to have_http_status(:moved_permanently)
      expect(response.location).to include("page=5")
      expect(response.location).to include("q=test")
    end
  end

  describe "English /lessons → series index" do
    it "redirects with 301" do
      get "/lessons"
      expect(response).to have_http_status(:moved_permanently)
      expect(response.location).to include(URI::DEFAULT_PARSER.escape(I18n.t("routes.series")))
    end
  end
end
