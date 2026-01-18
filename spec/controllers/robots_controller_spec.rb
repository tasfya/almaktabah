# frozen_string_literal: true

require "rails_helper"

RSpec.describe RobotsController, type: :controller do
  let!(:domain) { create(:domain, host: "localhost") }

  before do
    request.host = "localhost"
  end

  describe "GET #show" do
    it "returns a successful response" do
      get :show, format: :text
      expect(response).to be_successful
    end

    it "returns text/plain content type" do
      get :show, format: :text
      expect(response.content_type).to include("text/plain")
    end

    it "includes User-agent directive" do
      get :show, format: :text
      expect(response.body).to include("User-agent: *")
    end

    it "allows root path" do
      get :show, format: :text
      expect(response.body).to include("Allow: /")
    end

    it "disallows /avo/ path" do
      get :show, format: :text
      expect(response.body).to include("Disallow: /avo/")
    end

    it "disallows /jobs/ path" do
      get :show, format: :text
      expect(response.body).to include("Disallow: /jobs/")
    end

    it "includes sitemap URL with current host" do
      get :show, format: :text
      expect(response.body).to include("Sitemap: http://localhost/sitemap.xml")
    end

    context "with different host" do
      before do
        request.host = "example.com"
        create(:domain, host: "example.com")
      end

      it "uses the request host in sitemap URL" do
        get :show, format: :text
        expect(response.body).to include("Sitemap: http://example.com/sitemap.xml")
      end
    end
  end
end
