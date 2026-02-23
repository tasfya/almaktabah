# frozen_string_literal: true

require "rails_helper"

RSpec.describe SitemapService do
  let!(:domain) { create(:domain, host: "localhost") }
  let!(:scholar) { create(:scholar) }
  let(:service) { described_class.new(domain) }

  describe "#content_type_pages" do
    it "returns all content types" do
      pages = service.content_type_pages
      types = pages.map { |p| p[:type] }.uniq
      expect(types).to match_array(SitemapService::CONTENT_TYPES.keys)
    end

    it "returns page numbers starting at 1" do
      pages = service.content_type_pages
      expect(pages.all? { |p| p[:page] >= 1 }).to be true
    end
  end

  describe "#urls_for" do
    context "with static type" do
      it "returns root and about URLs" do
        urls = service.urls_for(:static)
        expect(urls.map { |u| u[:loc] }).to contain_exactly(:root, :about)
      end
    end

    context "with articles" do
      let!(:article) do
        article = create(:article, scholar: scholar, published: true, published_at: 1.day.ago)
        article.domains << domain
        article
      end

      it "returns published articles for domain" do
        urls = service.urls_for(:articles)
        expect(urls).to include(article)
      end

      it "excludes unpublished articles" do
        unpublished = create(:article, scholar: scholar, published: false)
        unpublished.domains << domain
        urls = service.urls_for(:articles)
        expect(urls).not_to include(unpublished)
      end

      it "excludes articles from other domains" do
        other_domain = create(:domain, host: "other.com")
        other_article = create(:article, scholar: scholar, published: true, published_at: 1.day.ago)
        other_article.domains = [ other_domain ]
        urls = service.urls_for(:articles)
        expect(urls).not_to include(other_article)
      end
    end

    context "with lessons" do
      let!(:series) { create(:series, scholar: scholar, published: true, published_at: 1.day.ago) }
      let!(:lesson) do
        lesson = create(:lesson, series: series, published: true, published_at: 1.day.ago)
        lesson.domains << domain
        lesson
      end

      it "returns published lessons for domain" do
        urls = service.urls_for(:lessons)
        expect(urls).to include(lesson)
      end
    end

    context "with listings type" do
      it "returns all listing page URLs" do
        urls = service.urls_for(:listings)
        expect(urls.map { |u| u[:loc] }).to contain_exactly(:articles, :books, :lectures, :series, :fatwas, :news)
      end
    end

    context "with pagination" do
      it "respects page parameter" do
        urls_page1 = service.urls_for(:articles, page: 1)
        urls_page2 = service.urls_for(:articles, page: 2)
        expect(urls_page1).to be_an(ActiveRecord::Relation)
        expect(urls_page2).to be_an(ActiveRecord::Relation)
      end
    end
  end

  describe "#page_count" do
    it "returns 1 for static type" do
      expect(service.page_count(:static)).to eq(1)
    end

    it "returns 1 for listings type" do
      expect(service.page_count(:listings)).to eq(1)
    end

    it "returns at least 1 for any content type" do
      SitemapService::CONTENT_TYPES.keys.each do |type|
        expect(service.page_count(type)).to be >= 1
      end
    end

    it "returns 0 for unknown type" do
      expect(service.page_count(:unknown)).to eq(0)
    end
  end

  describe "#latest_updated_at" do
    it "returns current time for static type" do
      result = service.latest_updated_at(:static)
      expect(result).to be_within(1.second).of(Time.current)
    end

    it "returns domain updated_at for listings type" do
      expect(service.latest_updated_at(:listings)).to be_within(1.second).of(domain.updated_at)
    end

    it "returns nil when no records exist" do
      expect(service.latest_updated_at(:articles)).to be_nil
    end

    context "with records" do
      let!(:article) do
        article = create(:article, scholar: scholar, published: true, published_at: 1.day.ago)
        article.domains << domain
        article
      end

      it "returns the latest updated_at" do
        expect(service.latest_updated_at(:articles)).to be_within(1.second).of(article.updated_at)
      end
    end
  end
end
