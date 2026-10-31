# frozen_string_literal: true

require "rails_helper"
require_relative "fixed_content"

# Every legacy or alternate URL, with the exact status and Location it answers
# with today. Locations are literal, not built with route helpers.
RSpec.describe "URL contract: redirects", type: :request do
  include_context "with fixed url contract content"

  u = UrlContract
  paths = UrlContract::SHOW_PATHS

  def expect_redirect(from, to:, status: :moved_permanently)
    get from
    expect(response).to have_http_status(status)
    expect(response.location).to eq(absolute(to))
  end

  describe "legacy index paths" do
    {
      "/lectures" => "/#{u::LECTURES}",
      "/lectures?page=5&q=test" => "/#{u::LECTURES}?page=5&q=test",
      "/fatwas" => "/#{u::FATWAS}",
      "/fatwas?page=2" => "/#{u::FATWAS}?page=2",
      "/news" => "/#{u::NEWS}",
      "/news?page=2&q=%D8%AE%D8%A8%D8%B1" => "/#{u::NEWS}?page=2&q=%D8%AE%D8%A8%D8%B1",
      "/lessons" => "/#{u::SERIES}",
      "/lessons?page=3" => "/#{u::SERIES}",
      "/#{u::LESSONS}" => "/#{u::SERIES}"
    }.each do |from, to|
      it("#{from} → 301 #{to}") { expect_redirect(from, to: to) }
    end
  end

  describe "legacy show paths" do
    {
      "/news/#{u::NEWS_ID}" => paths[:news],
      "/news/#{u::NEWS_SLUG}" => paths[:news],
      "/#{u::NEWS}/#{u::NEWS_ID}" => paths[:news],
      "/#{u::NEWS}/#{u::NEWS_SLUG}" => paths[:news],
      "/fatwas/#{u::FATWA_ID}" => paths[:fatwa],
      "/fatwas/#{u::FATWA_SLUG}" => paths[:fatwa],
      "/#{u::FATWAS}/#{u::FATWA_ID}" => paths[:fatwa],
      "/#{u::FATWAS}/#{u::FATWA_SLUG}" => paths[:fatwa],
      "/books/#{u::BOOK_ID}" => paths[:book],
      "/series/#{u::SERIES_ID}" => paths[:series],
      "/lectures/#{u::SERMON_ID}" => paths[:sermon],
      "/lectures/#{u::CONFERENCE_ID}" => paths[:conference],
      "/lectures/#{u::BENEFIT_ID}" => paths[:benefit],
      "/#{u::LESSONS}/#{u::LESSON_ID}" => paths[:lesson]
    }.each do |from, to|
      it("#{from} → 301 #{to}") { expect_redirect(from, to: to) }
    end
  end

  describe "legacy show paths for a missing record (soft 404, #613)" do
    {
      "/news/999999" => "/#{u::NEWS}",
      "/#{u::NEWS}/999999" => "/#{u::NEWS}",
      "/fatwas/999999" => "/#{u::FATWAS}",
      "/#{u::FATWAS}/999999" => "/#{u::FATWAS}",
      "/books/999999" => "/#{u::BOOKS}",
      "/series/999999" => "/#{u::SERIES}",
      "/lectures/999999" => "/#{u::LECTURES}",
      "/#{u::LESSONS}/999999" => "/#{u::SERIES}"
    }.each do |from, to|
      it("#{from} → 302 #{to}") { expect_redirect(from, to: to, status: :found) }
    end
  end

  describe "lecture kind segment" do
    it "redirects a wrong kind to the lecture's kind" do
      expect_redirect("/#{u::SCHOLAR_SLUG}/#{u::LECTURES}/#{u::KIND_CONFERENCE}/#{u::SERMON_SLUG}", to: paths[:sermon])
    end

    it "redirects a benefit requested under another kind" do
      expect_redirect("/#{u::SCHOLAR_SLUG}/#{u::LECTURES}/#{u::KIND_SERMON}/#{u::BENEFIT_SLUG}", to: paths[:benefit])
    end

    it "redirects a missing kind to the lecture's kind" do
      expect_redirect("/#{u::SCHOLAR_SLUG}/#{u::LECTURES}/#{u::CONFERENCE_SLUG}", to: paths[:conference])
    end

    it "redirects an unknown kind segment to the lecture's kind" do
      expect_redirect("/#{u::SCHOLAR_SLUG}/#{u::LECTURES}/sermon/#{u::SERMON_SLUG}", to: paths[:sermon])
    end
  end

  describe "numeric ids in place of slugs" do
    # slug_mismatch? accepts the record id as well as its slug, so these are
    # served directly (200) instead of redirecting to the slug URL.
    {
      book: "/#{u::SCHOLAR_SLUG}/#{u::BOOKS}/#{u::BOOK_ID}",
      sermon: "/#{u::SCHOLAR_SLUG}/#{u::LECTURES}/#{u::KIND_SERMON}/#{u::SERMON_ID}"
    }.each do |type, path|
      it "serves the #{type} at #{path}" do
        get path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "friendly_id slug history" do
    def rename_through_old_slug(record, attribute)
      original = record.public_send(attribute)
      record.update!(attribute => UrlContract::OLD_TITLE)
      record.update!(attribute => original)
    end

    {
      book: [ :title, "/#{u::SCHOLAR_SLUG}/#{u::BOOKS}/#{u::OLD_SLUG}" ],
      article: [ :title, "/#{u::SCHOLAR_SLUG}/#{u::ARTICLES}/#{u::OLD_SLUG}" ],
      series: [ :title, "/#{u::SCHOLAR_SLUG}/#{u::SERIES}/#{u::OLD_SLUG}" ],
      news: [ :title, "/#{u::SCHOLAR_SLUG}/#{u::NEWS}/#{u::OLD_SLUG}" ],
      fatwa: [ :title, "/#{u::SCHOLAR_SLUG}/#{u::FATWAS}/#{u::OLD_SLUG}" ],
      sermon: [ :title, "/#{u::SCHOLAR_SLUG}/#{u::LECTURES}/#{u::KIND_SERMON}/#{u::OLD_SLUG}" ]
    }.each do |type, (attribute, old_path)|
      it "redirects the old #{type} slug" do
        rename_through_old_slug(public_send(type), attribute)
        expect_redirect(old_path, to: paths[type])
      end
    end

    it "redirects a lesson under the old series slug" do
      rename_through_old_slug(series, :title)
      expect_redirect("/#{u::SCHOLAR_SLUG}/#{u::SERIES}/#{u::OLD_SLUG}/#{u::LESSONS}/#{u::LESSON_ID}", to: paths[:lesson])
    end

    it "redirects a page under the old scholar slug" do
      rename_through_old_slug(scholar, :full_name)
      expect_redirect("/#{u::OLD_SLUG}/#{u::BOOKS}/#{u::BOOK_SLUG}", to: paths[:book])
    end

    it "redirects a lesson under the old scholar slug" do
      rename_through_old_slug(scholar, :full_name)
      expect_redirect("/#{u::OLD_SLUG}/#{u::SERIES}/#{u::SERIES_SLUG}/#{u::LESSONS}/#{u::LESSON_ID}", to: paths[:lesson])
    end
  end
end
