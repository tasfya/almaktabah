# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Articles", type: :request do
  let!(:domain) { create(:domain, host: "localhost") }
  let!(:scholar) { create(:scholar) }
  let!(:published_article) { create(:article, published: true, published_at: 1.day.ago, scholar: scholar) }

  before do
    host! "localhost"
    create(:domain_assignment, domain: domain, assignable: published_article)
  end

  describe "GET /:scholar_id/articles/:id" do
    it "shows the article" do
      get article_path(scholar, published_article)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(ERB::Util.html_escape(published_article.title))
    end

    context "when accessed via old scholar slug" do
      it "redirects to canonical URL with 301" do
        old_slug = scholar.slug
        scholar.update!(first_name: "NewUniqueName", last_name: "NewUniqueLast", full_name: "NewUniqueName NewUniqueLast")

        get article_path(old_slug, published_article.id)
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(article_path(scholar, published_article))
      end
    end

    context "when accessed via old article slug" do
      it "redirects to canonical URL with 301" do
        old_slug = published_article.slug
        published_article.update!(title: "New Unique Article Title #{SecureRandom.hex(4)}")

        get article_path(scholar.to_param, old_slug)
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(article_path(scholar, published_article))
      end
    end

    context "when article is not found" do
      it "redirects to articles index" do
        get article_path(scholar.id, 999999)
        expect(response).to redirect_to(articles_path)
        expect(flash[:alert]).to eq(I18n.t("messages.article_not_found"))
      end
    end
  end
end
