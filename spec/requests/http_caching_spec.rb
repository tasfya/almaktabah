# frozen_string_literal: true

require "rails_helper"

RSpec.describe "HTTP caching headers", type: :request do
  let!(:domain) { create(:domain, host: "www.example.com") }
  let!(:scholar) { create(:scholar) }
  let!(:book) { create(:book, scholar: scholar, published: true).tap { |b| b.domains << domain } }

  before { host! "www.example.com" }

  around do |example|
    original = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = caching
    example.run
  ensure
    ActionController::Base.perform_caching = original
  end

  context "when caching is enabled (production)" do
    let(:caching) { true }

    it "lets browsers and the CDN cache content pages" do
      get book_path(scholar, book)
      expect(response.headers["Cache-Control"]).to eq("max-age=604800, public, stale-while-revalidate=3600")
    end

    it "lets browsers and the CDN cache the about page" do
      get about_path
      expect(response.headers["Cache-Control"]).to eq("max-age=3600, public")
    end
  end

  # Browsers would otherwise keep serving a cached page after a template edit.
  context "when caching is disabled (development default)" do
    let(:caching) { false }

    it "does not let browsers cache content pages" do
      get book_path(scholar, book)
      expect(response.headers["Cache-Control"]).to eq("max-age=0, private, must-revalidate")
    end

    it "does not let browsers cache the about page" do
      get about_path
      expect(response.headers["Cache-Control"]).to eq("max-age=0, private, must-revalidate")
    end
  end
end
