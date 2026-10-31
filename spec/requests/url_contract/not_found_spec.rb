# frozen_string_literal: true

require "rails_helper"
require_relative "fixed_content"

# URLs that must answer 404, so search engines drop them instead of indexing an
# error page or a redirect.
RSpec.describe "URL contract: not found", type: :request do
  include_context "with fixed url contract content"

  u = UrlContract
  paths = UrlContract::SHOW_PATHS

  describe "paths that used to route to controllers that never existed (#619)" do
    %w[/library /playlist/1 /category/1 /artist/1 /album/1].each do |path|
      it "answers 404 for #{path}" do
        get path
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "a host with no Domain row (#612)" do
    before { host! "unknown.example.test" }

    [ "/", paths[:book], "/sitemap.xml", "/sitemaps/books.xml", "/podcasts/feed" ].each do |path|
      it "answers 404 for #{path}" do
        get path
        expect(response).to have_http_status(:not_found)
      end
    end

    it "still serves the admin sign-in page" do
      get "/users/sign_in"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "missing or unpublished records (#613)" do
    {
      "/#{u::SCHOLAR_SLUG}/#{u::BOOKS}/missing" => [ "/#{u::BOOKS}", "messages.book_not_found" ],
      "/#{u::SCHOLAR_SLUG}/#{u::ARTICLES}/missing" => [ "/#{u::ARTICLES}", "messages.article_not_found" ],
      "/#{u::SCHOLAR_SLUG}/#{u::SERIES}/missing" => [ "/#{u::SERIES}", "messages.series_not_found" ],
      "/#{u::SCHOLAR_SLUG}/#{u::SERIES}/#{u::SERIES_SLUG}/#{u::LESSONS}/999999" => [ "/#{u::SERIES}", "messages.lesson_not_found" ],
      "/#{u::SCHOLAR_SLUG}/#{u::NEWS}/missing" => [ "/#{u::NEWS}", "messages.news_not_found" ],
      "/#{u::SCHOLAR_SLUG}/#{u::FATWAS}/missing" => [ "/#{u::FATWAS}", "messages.fatwa_not_found" ],
      "/#{u::SCHOLAR_SLUG}/#{u::LECTURES}/#{u::KIND_SERMON}/missing" => [ "/#{u::LECTURES}", "messages.lecture_not_found" ],
      "/missing-scholar/#{u::BOOKS}/#{u::BOOK_SLUG}" => [ "/#{u::BOOKS}", "messages.book_not_found" ]
    }.each do |path, (back_to, message)|
      it "answers 404 for #{path}, linking to #{back_to}" do
        get path
        expect(response).to be_not_found_page(I18n.t(message), back_to: back_to)
      end
    end

    {
      book: [ "/#{u::BOOKS}", "messages.book_not_found" ],
      article: [ "/#{u::ARTICLES}", "messages.article_not_found" ],
      series: [ "/#{u::SERIES}", "messages.series_not_found" ],
      lesson: [ "/#{u::SERIES}", "messages.lesson_not_found" ],
      news: [ "/#{u::NEWS}", "messages.news_not_found" ],
      fatwa: [ "/#{u::FATWAS}", "messages.fatwa_not_found" ],
      sermon: [ "/#{u::LECTURES}", "messages.lecture_not_found" ]
    }.each do |type, (back_to, message)|
      it "answers 404 for an unpublished #{type}, linking to #{back_to}" do
        public_send(type).update!(published: false)
        get paths[type]
        expect(response).to be_not_found_page(I18n.t(message), back_to: back_to)
      end
    end
  end

  describe "legacy show paths for a missing record (#613)" do
    {
      "/news/999999" => [ "/#{u::NEWS}", "messages.news_not_found" ],
      "/#{u::NEWS}/999999" => [ "/#{u::NEWS}", "messages.news_not_found" ],
      "/fatwas/999999" => [ "/#{u::FATWAS}", "messages.fatwa_not_found" ],
      "/#{u::FATWAS}/999999" => [ "/#{u::FATWAS}", "messages.fatwa_not_found" ],
      "/books/999999" => [ "/#{u::BOOKS}", "messages.book_not_found" ],
      "/series/999999" => [ "/#{u::SERIES}", "messages.series_not_found" ],
      "/lectures/999999" => [ "/#{u::LECTURES}", "messages.lecture_not_found" ],
      "/#{u::LESSONS}/999999" => [ "/#{u::SERIES}", "messages.lesson_not_found" ]
    }.each do |path, (back_to, message)|
      it "answers 404 for #{path}, linking to #{back_to}" do
        get path
        expect(response).to be_not_found_page(I18n.t(message), back_to: back_to)
      end
    end
  end
end
