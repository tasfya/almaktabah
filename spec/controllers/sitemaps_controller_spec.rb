# frozen_string_literal: true

require "rails_helper"

RSpec.describe SitemapsController, type: :controller do
  render_views

  let!(:domain) { create(:domain, host: "localhost") }
  let!(:scholar) { create(:scholar) }

  before do
    request.host = "localhost"
  end

  describe "GET #show" do
    it "returns a successful response" do
      get :show, format: :xml
      expect(response).to be_successful
    end

    it "returns XML content type" do
      get :show, format: :xml
      expect(response.content_type).to include("application/xml")
    end

    it "includes XML declaration" do
      get :show, format: :xml
      expect(response.body).to include('<?xml version="1.0" encoding="UTF-8"?>')
    end

    it "includes urlset namespace" do
      get :show, format: :xml
      expect(response.body).to include('xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"')
    end

    it "includes root URL" do
      get :show, format: :xml
      expect(response.body).to include("<loc>http://localhost/</loc>")
    end

    context "with published articles" do
      let!(:article) do
        article = create(:article, scholar: scholar, published: true, published_at: 1.day.ago)
        article.domains << domain
        article
      end

      it "includes article URLs" do
        get :show, format: :xml
        expect(response.body).to include(article_path(article, scholar_id: scholar.slug))
      end

      it "includes lastmod for articles" do
        get :show, format: :xml
        expect(response.body).to include("<lastmod>#{article.updated_at.strftime('%Y-%m-%d')}</lastmod>")
      end
    end

    context "with published books" do
      let!(:book) { create(:book, scholar: scholar, published: true, published_at: 1.day.ago) }

      it "includes book URLs" do
        get :show, format: :xml
        expect(response.body).to include(book_path(book, scholar_id: scholar.slug))
      end
    end

    context "with published lectures" do
      let!(:lecture) do
        lecture = create(:lecture, :with_domain, scholar: scholar, published: true, published_at: 1.day.ago)
        lecture
      end

      it "includes lecture URLs" do
        get :show, format: :xml
        expect(response.body).to include(CGI.escape(scholar.slug))
      end
    end

    context "with published series" do
      let!(:series) { create(:series, scholar: scholar, published: true, published_at: 1.day.ago) }

      it "includes series URLs" do
        get :show, format: :xml
        expect(response.body).to include(series_path(series, scholar_id: scholar.slug))
      end
    end

    context "with published fatwas" do
      let!(:fatwa) { create(:fatwa, scholar: scholar, published: true, published_at: 1.day.ago) }

      it "includes fatwa URLs" do
        get :show, format: :xml
        expect(response.body).to include(fatwa_path(fatwa))
      end
    end

    context "with published news" do
      let!(:news_item) { create(:news, published: true, published_at: 1.day.ago) }

      it "includes news URLs" do
        get :show, format: :xml
        expect(response.body).to include(news_path(news_item))
      end
    end

    context "with published scholars" do
      it "includes scholar URLs" do
        get :show, format: :xml
        expect(response.body).to include(scholar_path(scholar))
      end
    end

    context "with unpublished content" do
      let!(:unpublished_article) do
        article = create(:article, scholar: scholar, published: false)
        article.domains << domain
        article
      end

      it "does not include unpublished articles" do
        get :show, format: :xml
        expect(response.body).not_to include(article_path(unpublished_article, scholar_id: scholar.slug))
      end
    end

    context "with content from other domains" do
      let!(:other_domain) { create(:domain, host: "other.com") }
      let!(:other_article) do
        article = create(:article, scholar: scholar, published: true, published_at: 1.day.ago)
        article.domains = [ other_domain ]
        article.save!
        article
      end

      it "does not include content from other domains" do
        get :show, format: :xml
        expect(response.body).not_to include(article_path(other_article, scholar_id: scholar.slug))
      end
    end
  end
end
