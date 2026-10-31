# frozen_string_literal: true

require "rails_helper"

# A visitor lands on the home page, browses a listing and opens a record. The
# listing request specs stub the search with an empty result, so they never
# render a result card; here real records go through Typesense and every page
# of the journey is rendered with them: the home browse sections, the home
# search, each listing page, the card link and the show page it leads to.
RSpec.describe "Journey: browse a listing and open a record", :typesense, type: :request do
  include_context "with tenant domain"

  let(:scholar) { create(:scholar, full_name: "Abdul Aziz") }

  let!(:records) do
    {
      book: create(:book, title: "Journey Book", scholar: scholar),
      lecture: create(:lecture, title: "Journey Lecture Tawhid", scholar: scholar),
      series: create(:series, title: "Journey Series", scholar: scholar),
      article: create(:article, title: "Journey Article", scholar: scholar),
      fatwa: create(:fatwa, title: "Journey Fatwa", scholar: scholar),
      news: create(:news, title: "Journey News", scholar: scholar, published_at: 1.day.ago)
    }.each_value { |record| record.update!(domains: [ domain ]) }
  end

  before { index_records(records.values) }

  def show_path_for(record)
    case record
    when Book then book_path(scholar, record)
    when Lecture then lecture_path(scholar, record, kind: record.kind_for_url)
    when Series then series_path(scholar, record)
    when Article then article_path(scholar, record)
    when Fatwa then fatwa_path(scholar, record)
    when News then news_path(scholar, record)
    end
  end

  def listing_path_for(type)
    {
      book: books_path, lecture: lectures_path, series: series_index_path,
      article: articles_path, fatwa: fatwas_path, news: news_index_path
    }.fetch(type)
  end

  def card_link(record)
    html.css("turbo-frame#search_content a[href]").map { |a| a["href"] }.find { |href| href == show_path_for(record) }
  end

  def expect_card_leading_to_show_page(record)
    expect(response).to have_http_status(:ok)
    expect(card_link(record)).to be_present, "no card links to #{record.class} #{record.title.inspect}"
  end

  it "browses every collection on the home page and each card opens its record" do
    get root_path

    records.each_value { |record| expect_card_leading_to_show_page(record) }

    records.each_value do |record|
      get show_path_for(record)

      expect(response).to have_http_status(:ok)
      expect(html.at_css("h1")&.text.to_s.strip).to eq(record.title)
      # The series page has no share button of its own, only one per lesson.
      expect(html.at_css("dialog[id$='_share_modal']")).to be_present unless record.is_a?(Series)
    end
  end

  it "links each home section to its listing page" do
    get root_path

    view_all = html.css("a").select { |a| a.text.strip == I18n.t("search.view_all") }.map { |a| a["href"] }
    expect(view_all).to match_array(records.keys.map { |type| listing_path_for(type) })
  end

  it "finds a record from the home search and opens it" do
    get root_path, params: { q: "Tawhid" }

    expect_card_leading_to_show_page(records[:lecture])
    expect(response.body).not_to include("Journey Fatwa")
  end

  it "lists each collection on its listing page, searchable, and each card opens its record" do
    records.each do |type, record|
      get listing_path_for(type)
      expect_card_leading_to_show_page(record)

      get listing_path_for(type), params: { q: record.title }
      expect_card_leading_to_show_page(record)

      get card_link(record)
      expect(response).to have_http_status(:ok)
    end
  end

  it "shows none of this tenant's records on another tenant's listings" do
    host! other_domain.host

    get root_path
    expect(response).to have_http_status(:ok)
    records.each_value { |record| expect(response.body).not_to include(record.title) }

    records.each do |type, record|
      get listing_path_for(type)
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(record.title)
    end
  end
end
