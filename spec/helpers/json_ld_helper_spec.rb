# frozen_string_literal: true

require "rails_helper"

RSpec.describe JsonLdHelper, type: :helper do
  let(:domain) { create(:domain, host: "localhost", name: "Test Site", title: "Test Site") }
  let(:scholar) { create(:scholar, full_name: "Test Scholar") }

  before do
    assign(:domain, domain)

    # Define canonical_url as a helper method
    def helper.canonical_url
      "http://localhost/test"
    end

    allow(helper).to receive(:request).and_return(
      double(host: "localhost", protocol: "http://", original_url: "http://localhost/test")
    )
    allow(helper).to receive(:root_url).with(host: "localhost").and_return("http://localhost/")
    allow(helper).to receive(:t).with("site.name").and_return("Default Site")
    allow(helper).to receive(:url_for).and_return("http://localhost/file.jpg")
  end

  describe "#json_ld_tag" do
    it "returns a script tag with application/ld+json type" do
      data = { "@type": "Article", "name": "Test" }
      result = helper.json_ld_tag(data)

      expect(result).to include('type="application/ld+json"')
      expect(result).to include("<script")
      expect(result).to include("</script>")
    end

    it "converts data to JSON" do
      data = { "@type": "Article", "name": "Test Article" }
      result = helper.json_ld_tag(data)

      expect(result).to include('"@type":"Article"')
      expect(result).to include('"name":"Test Article"')
    end

    it "escapes </script> to prevent XSS attacks" do
      data = { "@type": "Article", "name": "</script><script>alert('xss')</script>" }
      result = helper.json_ld_tag(data)

      # Ruby's to_json escapes < and > as Unicode, preventing script injection
      expect(result).not_to include("</script><script>alert")
      expect(result).to include('\\u003c/script\\u003e')
    end
  end

  describe "#article_json_ld" do
    let(:article) do
      article = build_stubbed(:article,
        title: "Test Article",
        scholar: scholar,
        published_at: Time.zone.parse("2024-01-15 10:00:00"),
        updated_at: Time.zone.parse("2024-01-16 12:00:00")
      )
      allow(article).to receive(:content).and_return(nil)
      article
    end

    it "returns Article type" do
      result = helper.article_json_ld(article)
      expect(result[:@type]).to eq("Article")
    end

    it "includes schema.org context" do
      result = helper.article_json_ld(article)
      expect(result[:@context]).to eq("https://schema.org")
    end

    it "includes headline" do
      result = helper.article_json_ld(article)
      expect(result[:headline]).to eq("Test Article")
    end

    it "includes author information" do
      result = helper.article_json_ld(article)
      expect(result[:author][:@type]).to eq("Person")
      expect(result[:author][:name]).to eq(scholar.full_name)
    end

    it "includes publisher information" do
      result = helper.article_json_ld(article)
      expect(result[:publisher][:@type]).to eq("Organization")
      expect(result[:publisher][:name]).to eq("Test Site")
    end

    it "includes datePublished in ISO8601 format" do
      result = helper.article_json_ld(article)
      expect(result[:datePublished]).to eq(article.published_at.iso8601)
    end

    it "includes mainEntityOfPage" do
      result = helper.article_json_ld(article)
      expect(result[:mainEntityOfPage][:@type]).to eq("WebPage")
    end
  end

  describe "#book_json_ld" do
    let(:book) do
      book = build_stubbed(:book,
        title: "Test Book",
        description: "A test book description",
        scholar: scholar,
        published_at: Time.zone.parse("2024-01-01")
      )
      allow(book).to receive(:cover_image).and_return(double(attached?: false))
      book
    end

    it "returns Book type" do
      result = helper.book_json_ld(book)
      expect(result[:@type]).to eq("Book")
    end

    it "includes name" do
      result = helper.book_json_ld(book)
      expect(result[:name]).to eq("Test Book")
    end

    it "includes description" do
      result = helper.book_json_ld(book)
      expect(result[:description]).to eq("A test book description")
    end

    it "includes author information" do
      result = helper.book_json_ld(book)
      expect(result[:author][:@type]).to eq("Person")
      expect(result[:author][:name]).to eq(scholar.full_name)
    end

    it "includes datePublished year" do
      result = helper.book_json_ld(book)
      expect(result[:datePublished]).to eq("2024")
    end
  end

  describe "#lecture_json_ld" do
    context "with audio lecture" do
      let(:lecture) do
        lecture = build_stubbed(:lecture,
          title: "Test Lecture",
          description: "A test lecture",
          scholar: scholar,
          duration: 3600,
          published_at: Time.zone.parse("2024-01-15")
        )
        allow(lecture).to receive(:video).and_return(double(attached?: false))
        allow(lecture).to receive(:audio).and_return(double(attached?: true))
        allow(lecture).to receive(:thumbnail).and_return(double(attached?: false))
        lecture
      end

      it "returns AudioObject type for audio lectures" do
        result = helper.lecture_json_ld(lecture)
        expect(result[:@type]).to eq("AudioObject")
      end

      it "includes duration in ISO 8601 format" do
        result = helper.lecture_json_ld(lecture)
        expect(result[:duration]).to eq("PT3600S")
      end
    end

    context "with video lecture" do
      let(:lecture) do
        lecture = build_stubbed(:lecture,
          title: "Test Video Lecture",
          description: "A test video lecture",
          scholar: scholar,
          duration: 1800,
          published_at: Time.zone.parse("2024-01-15")
        )
        allow(lecture).to receive(:video).and_return(double(attached?: true))
        allow(lecture).to receive(:audio).and_return(double(attached?: false))
        allow(lecture).to receive(:thumbnail).and_return(double(attached?: false))
        lecture
      end

      it "returns VideoObject type for video lectures" do
        result = helper.lecture_json_ld(lecture)
        expect(result[:@type]).to eq("VideoObject")
      end
    end
  end

  describe "#fatwa_json_ld" do
    let(:fatwa) do
      fatwa = build_stubbed(:fatwa,
        title: "Test Fatwa",
        scholar: scholar
      )
      allow(fatwa).to receive(:question).and_return(
        double(present?: true, to_plain_text: "What is the ruling on this?")
      )
      allow(fatwa).to receive(:answer).and_return(
        double(present?: true, to_plain_text: "The ruling is as follows...")
      )
      fatwa
    end

    it "returns FAQPage type" do
      result = helper.fatwa_json_ld(fatwa)
      expect(result[:@type]).to eq("FAQPage")
    end

    it "includes mainEntity with Question" do
      result = helper.fatwa_json_ld(fatwa)
      expect(result[:mainEntity]).to be_an(Array)
      expect(result[:mainEntity].first[:@type]).to eq("Question")
    end

    it "includes question text" do
      result = helper.fatwa_json_ld(fatwa)
      expect(result[:mainEntity].first[:name]).to include("What is the ruling")
    end

    it "includes acceptedAnswer" do
      result = helper.fatwa_json_ld(fatwa)
      answer = result[:mainEntity].first[:acceptedAnswer]
      expect(answer[:@type]).to eq("Answer")
      expect(answer[:text]).to include("The ruling is")
    end
  end

  describe "#series_json_ld" do
    let(:series) do
      build_stubbed(:series,
        title: "Test Series",
        description: "A test series description",
        scholar: scholar
      )
    end

    it "returns Course type" do
      result = helper.series_json_ld(series)
      expect(result[:@type]).to eq("Course")
    end

    it "includes name" do
      result = helper.series_json_ld(series)
      expect(result[:name]).to eq("Test Series")
    end

    it "includes description" do
      result = helper.series_json_ld(series)
      expect(result[:description]).to eq("A test series description")
    end

    it "includes provider as Person" do
      result = helper.series_json_ld(series)
      expect(result[:provider][:@type]).to eq("Person")
      expect(result[:provider][:name]).to eq(scholar.full_name)
    end
  end

  describe "#news_json_ld" do
    let(:news) do
      news = build_stubbed(:news,
        title: "Test News",
        description: "News description",
        published_at: Time.zone.parse("2024-01-15 10:00:00"),
        updated_at: Time.zone.parse("2024-01-16 12:00:00"),
        scholar: nil
      )
      allow(news).to receive(:thumbnail).and_return(double(attached?: false))
      news
    end

    it "returns NewsArticle type" do
      result = helper.news_json_ld(news)
      expect(result[:@type]).to eq("NewsArticle")
    end

    it "includes headline" do
      result = helper.news_json_ld(news)
      expect(result[:headline]).to eq("Test News")
    end

    it "includes description" do
      result = helper.news_json_ld(news)
      expect(result[:description]).to eq("News description")
    end

    it "includes datePublished" do
      result = helper.news_json_ld(news)
      expect(result[:datePublished]).to eq(news.published_at.iso8601)
    end

    it "includes publisher" do
      result = helper.news_json_ld(news)
      expect(result[:publisher][:@type]).to eq("Organization")
    end

    context "with scholar" do
      let(:news_with_scholar) do
        news = build_stubbed(:news,
          title: "Test News",
          description: "News description",
          published_at: Time.zone.parse("2024-01-15"),
          scholar: scholar
        )
        allow(news).to receive(:thumbnail).and_return(double(attached?: false))
        news
      end

      it "includes author when scholar is present" do
        result = helper.news_json_ld(news_with_scholar)
        expect(result[:author][:@type]).to eq("Person")
        expect(result[:author][:name]).to eq(scholar.full_name)
      end
    end
  end
end
