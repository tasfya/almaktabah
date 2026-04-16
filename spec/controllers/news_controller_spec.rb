# frozen_string_literal: true

require "rails_helper"

RSpec.describe NewsController, type: :controller do
  before(:each) do
    Faker::UniqueGenerator.clear
    request.host = "localhost"
  end

  let!(:domain) { create(:domain, host: "localhost") }
  let!(:published_news) { create(:news, published: true, published_at: 1.day.ago) }

  describe "GET #show" do
    context "when news exists" do
      it "returns a successful response" do
        get :show, params: { scholar_id: published_news.scholar.slug, id: published_news.to_param }
        expect(response).to be_successful
      end

      it "assigns the requested news" do
        get :show, params: { scholar_id: published_news.scholar.slug, id: published_news.to_param }
        expect(assigns(:news)).to eq(published_news)
      end
    end

    context "when accessed via old scholar slug" do
      it "redirects to canonical URL with 301" do
        old_slug = published_news.scholar.slug
        published_news.scholar.update!(first_name: "NewUniqueName", last_name: "NewUniqueLast", full_name: "NewUniqueName NewUniqueLast")

        get :show, params: { scholar_id: old_slug, id: published_news.to_param }
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(news_path(published_news.scholar, published_news))
      end
    end

    context "when accessed via old news slug" do
      it "redirects to canonical slug URL with 301" do
        old_slug = published_news.slug
        published_news.update!(title: "New Unique News Title #{SecureRandom.hex(4)}")

        get :show, params: { scholar_id: published_news.scholar.slug, id: old_slug }
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(news_path(published_news.scholar, published_news))
      end
    end

    context "when scholar does not exist" do
      it "redirects to news index" do
        get :show, params: { scholar_id: "nonexistent-scholar", id: published_news.to_param }
        expect(response).to redirect_to(news_index_path)
        expect(flash[:alert]).to eq(I18n.t("messages.news_not_found"))
      end
    end

    context "when news does not exist" do
      it "redirects to news index" do
        get :show, params: { scholar_id: published_news.scholar.slug, id: "nonexistent-slug" }
        expect(response).to redirect_to(news_index_path)
        expect(flash[:alert]).to eq(I18n.t("messages.news_not_found"))
      end
    end
  end

  describe "GET #legacy_redirect" do
    it "redirects to canonical news URL with 301" do
      get :legacy_redirect, params: { id: published_news.slug }
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(news_path(published_news.scholar, published_news))
    end

    it "redirects to news index when not found" do
      get :legacy_redirect, params: { id: "nonexistent-slug" }
      expect(response).to redirect_to(news_index_path)
      expect(flash[:alert]).to eq(I18n.t("messages.news_not_found"))
    end
  end
end
