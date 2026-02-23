# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SEO Meta Tags", type: :request do
  let!(:domain) { create(:domain, host: "www.example.com", name: "Test Site") }
  let!(:scholar) { create(:scholar, full_name: "الشيخ محمد") }

  before do
    host! "www.example.com"
  end

  describe "Articles" do
    let!(:article) do
      article = create(:article,
        title: "Test Article Title",
        scholar: scholar,
        published: true,
        published_at: 1.day.ago
      )
      article.content = ActionText::RichText.new(body: "This is the article content for testing meta descriptions.")
      article.save!
      article.domains << domain
      article
    end

    it "includes title meta tag" do
      get article_path(article, scholar_id: scholar.slug)
      expect(response.body).to include("<title>Test Article Title")
    end

    it "includes description meta tag" do
      get article_path(article, scholar_id: scholar.slug)
      expect(response.body).to include('name="description"')
    end

    it "includes canonical URL" do
      get article_path(article, scholar_id: scholar.slug)
      expect(response.body).to include('rel="canonical"')
    end

    it "includes Open Graph title" do
      get article_path(article, scholar_id: scholar.slug)
      expect(response.body).to include('property="og:title"')
    end

    it "includes Open Graph type" do
      get article_path(article, scholar_id: scholar.slug)
      expect(response.body).to include('property="og:type"')
      expect(response.body).to include("article")
    end

    it "includes JSON-LD structured data" do
      get article_path(article, scholar_id: scholar.slug)
      expect(response.body).to include('type="application/ld+json"')
      expect(response.body).to include('"@type":"Article"')
    end
  end

  describe "Books" do
    let!(:book) do
      book = create(:book, title: "Test Book Title", description: "Book description text", scholar: scholar, published: true, published_at: 1.day.ago)
      book.domains << domain
      book
    end

    it "includes title meta tag" do
      get book_path(book, scholar_id: scholar.slug)
      expect(response.body).to include("<title>Test Book Title")
    end

    it "includes description meta tag from book description" do
      get book_path(book, scholar_id: scholar.slug)
      expect(response.body).to include('name="description"')
    end

    it "includes Open Graph type as book" do
      get book_path(book, scholar_id: scholar.slug)
      expect(response.body).to include('property="og:type"')
      expect(response.body).to include("book")
    end

    it "includes JSON-LD structured data" do
      get book_path(book, scholar_id: scholar.slug)
      expect(response.body).to include('type="application/ld+json"')
      expect(response.body).to include('"@type":"Book"')
    end
  end

  describe "Lectures" do
    let!(:lecture) do
      lecture = create(:lecture, title: "Test Lecture Title", description: "Lecture description", scholar: scholar, published: true, published_at: 1.day.ago)
      lecture.domains << domain
      lecture
    end

    it "includes title meta tag" do
      get lecture_path(lecture, scholar_id: scholar.slug, kind: lecture.kind_for_url)
      expect(response.body).to include("<title>")
      expect(response.body).to include("Test Lecture Title")
    end

    it "includes description meta tag" do
      get lecture_path(lecture, scholar_id: scholar.slug, kind: lecture.kind_for_url)
      expect(response.body).to include('name="description"')
    end

    it "includes JSON-LD structured data for video/audio" do
      get lecture_path(lecture, scholar_id: scholar.slug, kind: lecture.kind_for_url)
      expect(response.body).to include('type="application/ld+json"')
      expect(response.body).to match(/"@type":"(VideoObject|AudioObject)"/)
    end
  end

  describe "Fatwas" do
    let!(:fatwa) do
      fatwa = create(:fatwa, title: "Test Fatwa Title", scholar: scholar, published: true, published_at: 1.day.ago)
      fatwa.domains << domain
      fatwa
    end

    it "includes title meta tag" do
      get fatwa_path(fatwa)
      expect(response.body).to include("<title>Test Fatwa Title")
    end

    it "includes JSON-LD FAQPage structured data" do
      get fatwa_path(fatwa)
      expect(response.body).to include('type="application/ld+json"')
      expect(response.body).to include('"@type":"FAQPage"')
    end
  end

  describe "Series" do
    let!(:series) do
      series = create(:series, title: "Test Series Title", description: "Series description", scholar: scholar, published: true, published_at: 1.day.ago)
      series.domains << domain
      series
    end

    it "includes title meta tag" do
      get series_path(series, scholar_id: scholar.slug)
      expect(response.body).to include("<title>")
      expect(response.body).to include("Test Series Title")
    end

    it "includes JSON-LD Course structured data" do
      get series_path(series, scholar_id: scholar.slug)
      expect(response.body).to include('type="application/ld+json"')
      expect(response.body).to include('"@type":"Course"')
    end
  end

  describe "Lessons" do
    let!(:series) do
      series = create(:series, title: "Test Series", scholar: scholar, published: true, published_at: 1.day.ago)
      series.domains << domain
      series
    end
    let!(:lesson) do
      lesson = create(:lesson, title: "Test Lesson Title", description: "Lesson description text", series: series, published: true, published_at: 1.day.ago)
      lesson.domains << domain
      lesson
    end

    it "includes title meta tag" do
      get series_lesson_path(series, lesson, scholar_id: scholar.slug)
      expect(response.body).to include("<title>Test Lesson Title")
    end

    it "includes description meta tag" do
      get series_lesson_path(series, lesson, scholar_id: scholar.slug)
      expect(response.body).to include('name="description"')
    end

    it "includes canonical URL" do
      get series_lesson_path(series, lesson, scholar_id: scholar.slug)
      expect(response.body).to include('rel="canonical"')
    end

    it "includes Open Graph title" do
      get series_lesson_path(series, lesson, scholar_id: scholar.slug)
      expect(response.body).to include('property="og:title"')
    end
  end

  describe "News" do
    let!(:news) do
      news = create(:news, title: "Test News Title", description: "News description", published: true, published_at: 1.day.ago)
      news.domains << domain
      news
    end

    it "includes title meta tag" do
      get news_path(news)
      expect(response.body).to include("<title>Test News Title")
    end

    it "includes JSON-LD NewsArticle structured data" do
      get news_path(news)
      expect(response.body).to include('type="application/ld+json"')
      expect(response.body).to include('"@type":"NewsArticle"')
    end
  end

  describe "Canonical URL resolution" do
    context "when scholar has a default_domain" do
      let!(:scholar_domain) { create(:domain, host: "scholar.example.com", name: "Scholar Site") }
      let!(:scholar_with_domain) { create(:scholar, full_name: "عالم", default_domain: scholar_domain) }
      let!(:article) do
        article = create(:article, title: "Canonical Test", scholar: scholar_with_domain, published: true, published_at: 1.day.ago)
        article.domains << domain
        article
      end

      it "points to scholar's default domain" do
        get article_path(article, scholar_id: scholar_with_domain.slug)
        expect(response.body).to include('rel="canonical" href="http://scholar.example.com')
      end
    end

    context "when scholar has no default_domain" do
      let!(:ilm_domain) { create(:domain, host: "ilm.example.com", name: Domain::ILM_NAME) }
      let!(:book) do
        book = create(:book, title: "Ilm Fallback Book", scholar: scholar, published: true, published_at: 1.day.ago)
        book.domains << domain
        book
      end

      it "falls back to ilm domain" do
        get book_path(book, scholar_id: scholar.slug)
        expect(response.body).to include('rel="canonical" href="http://ilm.example.com')
      end
    end

    context "when no scholar default_domain and no ilm domain" do
      let!(:fatwa) do
        fatwa = create(:fatwa, title: "Fallback Fatwa", scholar: scholar, published: true, published_at: 1.day.ago)
        fatwa.domains << domain
        fatwa
      end

      it "falls back to current request domain" do
        get fatwa_path(fatwa)
        expect(response.body).to include('rel="canonical" href="http://www.example.com')
      end
    end
  end

  describe "Default meta tags" do
    let!(:fatwa) do
      fatwa = create(:fatwa, title: "Test", scholar: scholar, published: true, published_at: 1.day.ago)
      fatwa.domains << domain
      fatwa
    end

    it "includes site name in meta tags" do
      get fatwa_path(fatwa)
      expect(response.body).to include('property="og:site_name"')
    end

    it "includes Twitter card meta tag" do
      get fatwa_path(fatwa)
      expect(response.body).to include('name="twitter:card"')
    end

    it "includes locale in Open Graph" do
      get fatwa_path(fatwa)
      expect(response.body).to include('property="og:locale"')
      expect(response.body).to include("ar_AR")
    end
  end

  describe "Robots noindex directives" do
    before { stub_typesense_search(empty_search_result) }

    it "does not add noindex on home page without params" do
      get root_path
      expect(response.body).not_to include('content="noindex')
    end

    it "adds noindex on home page with search query" do
      get root_path, params: { q: "test" }
      expect(response.body).to include('content="noindex, follow"')
    end

    it "adds noindex on home page with scholars filter" do
      get root_path, params: { scholars: [ "some-scholar" ] }
      expect(response.body).to include('content="noindex, follow"')
    end

    it "adds noindex on home page with content_types filter" do
      get root_path, params: { content_types: [ "article" ] }
      expect(response.body).to include('content="noindex, follow"')
    end

    it "does not add noindex on listing page 1 with results" do
      stub_typesense_search(build_search_result(hits_by_type: { articles: [ build_search_hit(type: :article, title: "Test") ] }, total: 1))
      get articles_path
      expect(response.body).not_to include('content="noindex')
    end

    it "adds noindex on empty listing page" do
      get articles_path
      expect(response.body).to include('content="noindex, follow"')
    end

    it "adds noindex on listing page 2" do
      get articles_path, params: { page: 2 }
      expect(response.body).to include('content="noindex, follow"')
    end

    it "adds noindex on listing page with scholars filter" do
      get articles_path, params: { scholars: [ "xyz" ] }
      expect(response.body).to include('content="noindex, follow"')
    end

    it "does not add noindex on detail page" do
      article = create(:article, title: "Noindex Test", scholar: scholar, published: true, published_at: 1.day.ago)
      article.domains << domain
      get article_path(article, scholar_id: scholar.slug)
      expect(response.body).not_to include('content="noindex')
    end
  end
end
