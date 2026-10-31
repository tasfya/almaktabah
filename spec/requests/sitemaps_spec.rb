# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sitemaps", type: :request do
  let!(:domain) { create(:domain, host: "localhost") }
  let!(:scholar) { create(:scholar) }

  before { host! "localhost" }

  def published_on_domain(factory, **attrs)
    create(factory, published: true, published_at: 1.day.ago, **attrs).tap { |record| record.domains << domain }
  end

  describe "GET /sitemap.xml" do
    it "returns a sitemap index" do
      get "/sitemap.xml"
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("application/xml")
      expect(response.body).to include('xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"')
    end

    it "excludes empty content types from sitemap index" do
      get "/sitemap.xml"
      expect(response.body).to include("/sitemaps/static.xml")
      expect(response.body).to include("/sitemaps/listings.xml")
      expect(response.body).not_to include("/sitemaps/articles.xml")
    end

    it "includes content types with records" do
      published_on_domain(:article, scholar: scholar)
      get "/sitemap.xml"
      expect(response.body).to include("/sitemaps/articles.xml")
    end
  end

  describe "GET /sitemaps/:type.xml" do
    context "with type=static" do
      it "includes the root and about URLs" do
        get sitemap_content_path(type: "static")
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("<loc>http://localhost/</loc>")
        expect(response.body).to include("<loc>http://localhost/about</loc>")
      end
    end

    context "with type=articles" do
      let!(:article) { published_on_domain(:article, scholar: scholar) }

      it "includes article URLs with lastmod" do
        get sitemap_content_path(type: "articles")
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(article_path(scholar, article))
        expect(response.body).to include("<lastmod>#{article.updated_at.strftime('%Y-%m-%d')}</lastmod>")
      end
    end

    it "includes book URLs" do
      book = published_on_domain(:book, scholar: scholar)
      get sitemap_content_path(type: "books")
      expect(response.body).to include(book_path(scholar, book))
    end

    it "includes lecture URLs" do
      create(:lecture, :with_domain, scholar: scholar, published: true, published_at: 1.day.ago)
      get sitemap_content_path(type: "lectures")
      expect(response.body).to include(CGI.escape(scholar.slug))
    end

    it "includes series URLs" do
      series = published_on_domain(:series, scholar: scholar)
      get sitemap_content_path(type: "series")
      expect(response.body).to include(series_path(scholar, series))
    end

    it "includes fatwa URLs" do
      fatwa = published_on_domain(:fatwa, scholar: scholar)
      get sitemap_content_path(type: "fatwas")
      expect(response.body).to include(fatwa_path(scholar, fatwa))
    end

    it "includes news URLs" do
      news_item = published_on_domain(:news, scholar: scholar)
      get sitemap_content_path(type: "news")
      expect(response.body).to include(news_path(scholar, news_item))
    end

    it "includes lesson URLs" do
      series = create(:series, scholar: scholar, published: true, published_at: 1.day.ago)
      lesson = published_on_domain(:lesson, series: series)
      get sitemap_content_path(type: "lessons")
      expect(response.body).to include(series_lesson_path(scholar, series, lesson))
    end

    context "with pagination" do
      it "requests the paginated path" do
        expect(sitemap_content_path(type: "articles", page: "999")).to eq("/sitemaps/articles-999.xml")
      end

      it "returns 404 for page number too high" do
        get sitemap_content_path(type: "articles", page: "999")
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for page 0" do
        get sitemap_content_path(type: "articles", page: "0")
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for page 1 of empty content type" do
        get sitemap_content_path(type: "articles", page: "1")
        expect(response).to have_http_status(:not_found)
      end

      it "returns success for page 1 with records" do
        published_on_domain(:article, scholar: scholar)
        get sitemap_content_path(type: "articles", page: "1")
        expect(response).to have_http_status(:ok)
      end
    end

    it "does not include unpublished articles" do
      unpublished_article = create(:article, scholar: scholar, published: false).tap { |a| a.domains << domain }
      get sitemap_content_path(type: "articles")
      expect(response.body).not_to include(article_path(scholar, unpublished_article))
    end

    it "does not include content from other domains" do
      other_domain = create(:domain, host: "other.com")
      other_article = create(:article, scholar: scholar, published: true, published_at: 1.day.ago)
      other_article.update!(domains: [ other_domain ])

      get sitemap_content_path(type: "articles")
      expect(response.body).not_to include(article_path(scholar, other_article))
    end
  end
end
