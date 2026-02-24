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
    context "when accessed via old slug" do
      it "redirects to canonical slug URL with 301" do
        old_slug = published_news.slug
        published_news.update!(title: "New Unique News Title #{SecureRandom.hex(4)}")

        get :show, params: { id: old_slug }
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(news_path(published_news))
      end
    end

    context "when news does not exist" do
      it "redirects to news index" do
        get :show, params: { id: "nonexistent-slug" }
        expect(response).to redirect_to(news_index_path)
        expect(flash[:alert]).to eq(I18n.t("messages.news_not_found"))
      end
    end
  end
end
