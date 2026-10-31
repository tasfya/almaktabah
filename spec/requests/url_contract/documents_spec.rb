# frozen_string_literal: true

require "rails_helper"
require_relative "fixed_content"

# Golden files for the documents crawlers and podcast apps read: the sitemap
# index, each per-type sitemap, the podcast feed and the SEO part of <head> on
# every show page. Regenerate after an intended change with
#   UPDATE_GOLDEN=1 bin/worktree test spec/requests/url_contract/documents_spec.rb
RSpec.describe "URL contract: crawler documents", type: :request do
  include_context "with fixed url contract content"

  # Records share one frozen updated_at, so their database order is not
  # defined; compare the <url> entries sorted by their text.
  def sorted_urlset(xml)
    doc = Nokogiri::XML(xml, &:noblanks)
    entries = doc.root.element_children.sort_by(&:text)
    entries.each(&:unlink)
    entries.each { |entry| doc.root.add_child(entry) }
    doc.to_xml(indent: 2)
  end

  describe "sitemaps" do
    it "pins the sitemap index" do
      get "/sitemap.xml"
      expect(response).to match_golden("url_contract/sitemaps/index.xml")
    end

    %w[articles books lectures series fatwas news lessons listings static].each do |type|
      it "pins sitemaps/#{type}.xml" do
        get "/sitemaps/#{type}.xml"
        expect(response).to have_http_status(:ok)
        expect(response).to match_golden("url_contract/sitemaps/#{type}.xml").normalized_by { |xml| sorted_urlset(xml) }
      end
    end
  end

  describe "podcast feed" do
    let(:tenant_domain_attributes) do
      {
        name: "contract", title: "Contract Site", description: "Contract description",
        podcast_enabled: true, podcast_title: "Contract Podcast", podcast_author: "Contract Author",
        podcast_owner_email: "owner@example.com", podcast_artwork_url_override: "https://cdn.example.com/art.jpg"
      }
    end

    def with_final_audio(record, published_at:)
      record.final_audio.attach(io: Rails.root.join("spec/files/audio.mp3").open, filename: "audio.mp3", content_type: "audio/mpeg")
      record.update!(published_at: published_at)
    end

    before do
      with_final_audio(sermon, published_at: 4.days.ago)
      with_final_audio(conference, published_at: 3.days.ago)
      with_final_audio(benefit, published_at: 2.days.ago)
      with_final_audio(lesson, published_at: 1.day.ago)
    end

    it "pins the feed (benefit lectures excluded, guid <type>-<id>@host)" do
      get "/podcasts/feed"
      expect(response).to have_http_status(:ok)
      expect(response).to match_golden("url_contract/podcasts/feed.xml")
        .normalized_by { |xml| xml.gsub(/(<enclosure url=")[^"]+/, '\\1BLOB_URL') }
    end

    it "pins the guids" do
      get "/podcasts/feed"
      guids = Nokogiri::XML(response.body).xpath("//item/guid").map(&:text)
      expect(guids).to eq([ "lesson-#{UrlContract::LESSON_ID}@localhost", "lecture-#{UrlContract::CONFERENCE_ID}@localhost", "lecture-#{UrlContract::SERMON_ID}@localhost" ])
    end

    it "answers 404 when the domain's podcast is disabled" do
      domain.update!(podcast_enabled: false)
      get "/podcasts/feed"
      expect(response).to have_http_status(:not_found)
      expect(response.body).to be_empty
    end
  end

  describe "<head> of each show page" do
    def head_snapshot
      doc = html
      {
        "title" => doc.at_css("head title")&.text,
        "canonical" => doc.at_css('link[rel="canonical"]')&.[]("href"),
        "og:url" => doc.at_css('meta[property="og:url"]')&.[]("content"),
        "og:type" => doc.at_css('meta[property="og:type"]')&.[]("content"),
        "robots" => doc.at_css('meta[name="robots"]')&.[]("content"),
        "json_ld" => json_ld.map do |entry|
          entry.slice("@type", "url").merge("mainEntityOfPage.@id" => entry.dig("mainEntityOfPage", "@id")).compact
        end
      }
    end

    UrlContract::SHOW_PATHS.each do |type, path|
      it "pins the #{type} page" do
        get path
        expect(response).to have_http_status(:ok)
        expect(JSON.pretty_generate(head_snapshot) + "\n").to match_golden("url_contract/heads/#{type}.json")
      end
    end
  end
end
