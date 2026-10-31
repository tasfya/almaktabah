# frozen_string_literal: true

require "rails_helper"

RSpec.describe "News", type: :request do
  let!(:domain) { create(:domain, host: "localhost") }
  let!(:published_news) { create(:news, published: true, published_at: 1.day.ago) }

  before { host! "localhost" }

  describe "GET /:scholar_id/news/:id" do
    context "when news exists" do
      it "shows the news" do
        get news_path(published_news.scholar.slug, published_news.to_param)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(ERB::Util.html_escape(published_news.title))
      end
    end

    context "when accessed via old scholar slug" do
      it "redirects to canonical URL with 301" do
        old_slug = published_news.scholar.slug
        published_news.scholar.update!(first_name: "NewUniqueName", last_name: "NewUniqueLast", full_name: "NewUniqueName NewUniqueLast")

        get news_path(old_slug, published_news.to_param)
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(news_path(published_news.scholar, published_news))
      end
    end

    context "when accessed via old news slug" do
      it "redirects to canonical slug URL with 301" do
        old_slug = published_news.slug
        published_news.update!(title: "New Unique News Title #{SecureRandom.hex(4)}")

        get news_path(published_news.scholar.slug, old_slug)
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(news_path(published_news.scholar, published_news))
      end
    end

    context "when scholar does not exist" do
      it "redirects to news index" do
        get news_path("nonexistent-scholar", published_news.to_param)
        expect(response).to redirect_to(news_index_path)
        expect(flash[:alert]).to eq(I18n.t("messages.news_not_found"))
      end
    end

    context "when news does not exist" do
      it "redirects to news index" do
        get news_path(published_news.scholar.slug, "nonexistent-slug")
        expect(response).to redirect_to(news_index_path)
        expect(flash[:alert]).to eq(I18n.t("messages.news_not_found"))
      end
    end
  end

  describe "GET /news/:id (legacy)" do
    it "redirects to canonical news URL with 301" do
      get legacy_news_path(published_news.slug)
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(news_path(published_news.scholar, published_news))
    end

    it "redirects to news index when not found" do
      get legacy_news_path("nonexistent-slug")
      expect(response).to redirect_to(news_index_path)
      expect(flash[:alert]).to eq(I18n.t("messages.news_not_found"))
    end
  end
end
