# frozen_string_literal: true

require "rails_helper"
require_relative "fixed_content"

# Current behavior that is probably wrong, pinned so that fixing it is a
# deliberate, reviewed change. Each block names its GitHub issue; when an issue
# is fixed, update the expectation here in the same PR.
RSpec.describe "URL contract: known issues", type: :request do
  include_context "with fixed url contract content"

  u = UrlContract
  paths = UrlContract::SHOW_PATHS

  describe "a host with no Domain row (#612)" do
    # @domain is nil, so the first `@domain.id` raises. In production that is a
    # 500 page; in the test env the error is not rescuable and reaches the spec.
    before { host! "unknown.example.test" }

    # The home page is left out: it queries Typesense before it reaches
    # @domain, so its failure depends on the search backend.
    {
      paths[:book] => NoMethodError,
      "/sitemap.xml" => ArgumentError,
      "/podcasts/feed" => NoMethodError
    }.each do |path, error|
      it "raises #{error} for #{path}" do
        expect { get path }.to raise_error(error)
      end
    end
  end

  describe "missing or unpublished records answer 302 to the index (#613)" do
    {
      "/#{u::SCHOLAR_SLUG}/#{u::BOOKS}/missing" => "/#{u::BOOKS}",
      "/#{u::SCHOLAR_SLUG}/#{u::ARTICLES}/missing" => "/#{u::ARTICLES}",
      "/#{u::SCHOLAR_SLUG}/#{u::SERIES}/missing" => "/#{u::SERIES}",
      "/#{u::SCHOLAR_SLUG}/#{u::SERIES}/#{u::SERIES_SLUG}/#{u::LESSONS}/999999" => "/#{u::SERIES}",
      "/#{u::SCHOLAR_SLUG}/#{u::NEWS}/missing" => "/#{u::NEWS}",
      "/#{u::SCHOLAR_SLUG}/#{u::FATWAS}/missing" => "/#{u::FATWAS}",
      "/#{u::SCHOLAR_SLUG}/#{u::LECTURES}/#{u::KIND_SERMON}/missing" => "/#{u::LECTURES}",
      "/missing-scholar/#{u::BOOKS}/#{u::BOOK_SLUG}" => "/#{u::BOOKS}"
    }.each do |from, to|
      it "#{from} → 302 #{to}" do
        get from
        expect(response).to have_http_status(:found)
        expect(response.location).to eq(absolute(to))
      end
    end

    {
      book: "/#{u::BOOKS}",
      article: "/#{u::ARTICLES}",
      series: "/#{u::SERIES}",
      lesson: "/#{u::SERIES}",
      news: "/#{u::NEWS}",
      fatwa: "/#{u::FATWAS}",
      sermon: "/#{u::LECTURES}"
    }.each do |type, to|
      it "redirects an unpublished #{type} with 302 to #{to}" do
        public_send(type).update!(published: false)
        get paths[type]
        expect(response).to have_http_status(:found)
        expect(response.location).to eq(absolute(to))
      end
    end
  end

  describe "sitemap <loc> host vs canonical host (#614)" do
    # The sitemap builds every <loc> on request.host, while the show page's
    # canonical points at the scholar's default domain. When they differ, the
    # sitemap lists URLs whose canonical is on another host.
    before { scholar.update!(default_domain: other_domain) }

    it "lists the book on the requesting host" do
      get "/sitemaps/books.xml"
      expect(sitemap_locs).to eq([ absolute(paths[:book]) ])
    end

    it "gives the same book a canonical on the scholar's default domain" do
      get paths[:book]
      expect(response).to have_canonical(absolute(paths[:book], host: "other.example.com"))
      expect(response).to have_meta_tag("og:url", absolute(paths[:book], host: "other.example.com"))
    end

    it "agrees when the scholar has no default domain" do
      scholar.update!(default_domain: nil)
      get "/sitemaps/books.xml"
      sitemap = sitemap_locs
      get paths[:book]
      expect(response).to have_canonical(sitemap.first)
    end
  end

  describe "podcast episode <link> host (#615)" do
    # Lecture#podcast_episode_url / Lesson#podcast_episode_url use the
    # record's first domain assignment, not the domain serving the feed.
    let(:tenant_domain_attributes) do
      { name: "contract", title: "Contract Site", podcast_enabled: true, podcast_title: "Contract Podcast", podcast_owner_email: "owner@example.com" }
    end

    before do
      sermon.domain_assignments.destroy_all
      sermon.domain_assignments.create!(domain: other_domain)
      sermon.domain_assignments.create!(domain: domain)
      sermon.final_audio.attach(io: Rails.root.join("spec/files/audio.mp3").open, filename: "audio.mp3", content_type: "audio/mpeg")
    end

    it "links the episode on the first assigned domain" do
      get "/podcasts/feed"
      links = Nokogiri::XML(response.body).xpath("//item/link").map(&:text)
      expect(links).to eq([ "https://other.example.com#{paths[:sermon]}" ])
    end
  end

  describe "routes to controllers that do not exist" do
    # ActionDispatch::MissingController is not in rescue_responses, so these
    # answer 500 in production rather than 404.
    %w[/library /playlist/1 /category/1 /artist/1 /album/1].each do |path|
      it "raises MissingController for #{path}" do
        expect { get path }.to raise_error(ActionDispatch::MissingController)
      end
    end
  end
end
