# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArticlesController, type: :controller do
  before(:each) do
    Faker::UniqueGenerator.clear
    request.host = "localhost"
  end

  let(:domain) { create(:domain, host: "localhost") }
  let!(:scholar) { create(:scholar) }
  let!(:published_article) { create(:article, published: true, published_at: 1.day.ago, scholar: scholar) }

  before do
    allow(controller).to receive(:set_domain)
    controller.instance_variable_set(:@domain, domain)

    create(:domain_assignment, domain: domain, assignable: published_article)
  end

  describe "GET #show" do
    context "when accessed via old scholar slug" do
      it "redirects to canonical URL with 301" do
        old_slug = scholar.slug
        scholar.update!(first_name: "NewUniqueName", last_name: "NewUniqueLast", full_name: "NewUniqueName NewUniqueLast")

        get :show, params: { scholar_id: old_slug, id: published_article.id }
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(article_path(scholar, published_article))
      end
    end

    context "when accessed via old article slug" do
      it "redirects to canonical URL with 301" do
        old_slug = published_article.slug
        published_article.update!(title: "New Unique Article Title #{SecureRandom.hex(4)}")

        get :show, params: { scholar_id: scholar.to_param, id: old_slug }
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(article_path(scholar, published_article))
      end
    end

    context "when article is not found" do
      it "redirects to articles index" do
        get :show, params: { scholar_id: scholar.id, id: 999999 }
        expect(response).to redirect_to(articles_path)
        expect(flash[:alert]).to eq(I18n.t("messages.article_not_found"))
      end
    end
  end
end
