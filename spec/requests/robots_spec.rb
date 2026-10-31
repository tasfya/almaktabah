# frozen_string_literal: true

require "rails_helper"

RSpec.describe "robots.txt", type: :request do
  let!(:domain) { create(:domain, host: "localhost") }

  before { host! "localhost" }

  describe "GET /robots.txt" do
    it "returns plain text" do
      get "/robots.txt"
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/plain")
    end

    it "allows the site except admin and jobs" do
      get "/robots.txt"
      expect(response.body).to include("User-agent: *")
      expect(response.body).to include("Allow: /")
      expect(response.body).to include("Disallow: /avo/")
      expect(response.body).to include("Disallow: /jobs/")
    end

    it "includes sitemap URL with current host" do
      get "/robots.txt"
      expect(response.body).to include("Sitemap: http://localhost/sitemap.xml")
    end

    context "with different host" do
      before do
        create(:domain, host: "example.com")
        host! "example.com"
      end

      it "uses the request host in sitemap URL" do
        get "/robots.txt"
        expect(response.body).to include("Sitemap: http://example.com/sitemap.xml")
      end
    end

    context "when DISALLOW_ROBOTS is set" do
      around do |example|
        ENV["DISALLOW_ROBOTS"] = "true"
        example.run
      ensure
        ENV.delete("DISALLOW_ROBOTS")
      end

      it "disallows the whole site and advertises no sitemap" do
        get "/robots.txt"
        expect(response.body).to eq("User-agent: *\nDisallow: /\n")
      end
    end
  end
end
