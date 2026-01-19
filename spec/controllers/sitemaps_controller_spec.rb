# frozen_string_literal: true

require "rails_helper"

RSpec.describe SitemapsController, type: :controller do
  render_views

  let!(:domain) { create(:domain, host: "localhost") }
  let!(:scholar) { create(:scholar) }

  before do
    request.host = "localhost"
  end

  describe "GET #index" do
    it "returns a successful response" do
      get :index, format: :xml
      expect(response).to be_successful
    end

    it "returns XML content type" do
      get :index, format: :xml
      expect(response.content_type).to include("application/xml")
    end

    it "includes sitemapindex namespace" do
      get :index, format: :xml
      expect(response.body).to include('xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"')
    end

    it "includes sitemap entries for each content type" do
      get :index, format: :xml
      SitemapService::CONTENT_TYPES.keys.each do |type|
        expect(response.body).to include("/sitemaps/#{type}.xml")
      end
    end
  end

  describe "GET #show" do
    context "with type=static" do
      it "returns a successful response" do
        get :show, params: { type: "static" }, format: :xml
        expect(response).to be_successful
      end

      it "includes root URL" do
        get :show, params: { type: "static" }, format: :xml
        expect(response.body).to include("<loc>http://localhost/</loc>")
      end

      it "includes about URL" do
        get :show, params: { type: "static" }, format: :xml
        expect(response.body).to include("<loc>http://localhost/about</loc>")
      end
    end

    context "with type=articles" do
      let!(:article) do
        article = create(:article, scholar: scholar, published: true, published_at: 1.day.ago)
        article.domains << domain
        article
      end

      it "returns a successful response" do
        get :show, params: { type: "articles" }, format: :xml
        expect(response).to be_successful
      end

      it "includes article URLs" do
        get :show, params: { type: "articles" }, format: :xml
        expect(response.body).to include(article_path(article, scholar_id: scholar.slug))
      end

      it "includes lastmod for articles" do
        get :show, params: { type: "articles" }, format: :xml
        expect(response.body).to include("<lastmod>#{article.updated_at.strftime('%Y-%m-%d')}</lastmod>")
      end
    end

    context "with type=books" do
      let!(:book) { create(:book, scholar: scholar, published: true, published_at: 1.day.ago) }

      it "includes book URLs" do
        get :show, params: { type: "books" }, format: :xml
        expect(response.body).to include(book_path(book, scholar_id: scholar.slug))
      end
    end

    context "with type=lectures" do
      let!(:lecture) { create(:lecture, :with_domain, scholar: scholar, published: true, published_at: 1.day.ago) }

      it "includes lecture URLs" do
        get :show, params: { type: "lectures" }, format: :xml
        expect(response.body).to include(CGI.escape(scholar.slug))
      end
    end

    context "with type=series" do
      let!(:series) { create(:series, scholar: scholar, published: true, published_at: 1.day.ago) }

      it "includes series URLs" do
        get :show, params: { type: "series" }, format: :xml
        expect(response.body).to include(series_path(series, scholar_id: scholar.slug))
      end
    end

    context "with type=fatwas" do
      let!(:fatwa) { create(:fatwa, scholar: scholar, published: true, published_at: 1.day.ago) }

      it "includes fatwa URLs" do
        get :show, params: { type: "fatwas" }, format: :xml
        expect(response.body).to include(fatwa_path(fatwa))
      end
    end

    context "with type=news" do
      let!(:news_item) { create(:news, published: true, published_at: 1.day.ago) }

      it "includes news URLs" do
        get :show, params: { type: "news" }, format: :xml
        expect(response.body).to include(news_path(news_item))
      end
    end

    context "with type=lessons" do
      let!(:series) { create(:series, scholar: scholar, published: true, published_at: 1.day.ago) }
      let!(:lesson) do
        lesson = create(:lesson, series: series, published: true, published_at: 1.day.ago)
        lesson.domains << domain
        lesson
      end

      it "includes lesson URLs" do
        get :show, params: { type: "lessons" }, format: :xml
        expect(response.body).to include(lesson_path(lesson))
      end
    end

    context "with type=scholars" do
      it "includes scholar URLs" do
        get :show, params: { type: "scholars" }, format: :xml
        expect(response.body).to include(scholar_path(scholar))
      end
    end

    context "with pagination" do
      it "returns 404 for page number too high" do
        get :show, params: { type: "articles", page: "999" }, format: :xml
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for page 0" do
        get :show, params: { type: "articles", page: "0" }, format: :xml
        expect(response).to have_http_status(:not_found)
      end

      it "returns success for page 1" do
        get :show, params: { type: "articles", page: "1" }, format: :xml
        expect(response).to be_successful
      end
    end

    context "with unpublished content" do
      let!(:unpublished_article) do
        article = create(:article, scholar: scholar, published: false)
        article.domains << domain
        article
      end

      it "does not include unpublished articles" do
        get :show, params: { type: "articles" }, format: :xml
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
        get :show, params: { type: "articles" }, format: :xml
        expect(response.body).not_to include(article_path(other_article, scholar_id: scholar.slug))
      end
    end
  end
end
