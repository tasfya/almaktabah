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
end
