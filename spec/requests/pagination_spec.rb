# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pagination", type: :request do
  let!(:domain) { create(:domain, host: "www.example.com") }
  let(:headers) { { "HOST" => domain.host } }

  def series_index_path
    "/%D8%A7%D9%84%D8%B3%D9%84%D8%A7%D8%B3%D9%84"
  end

  describe "pagination links preserve query parameters" do
    it "includes scholar filter in pagination links" do
      hits = 3.times.map do |i|
        build_search_hit(type: :series, title: "Series #{i}", scholar_name: "Test Scholar")
      end
      stub_typesense_search(build_search_result(
        hits_by_type: { series: hits },
        total: 3,
        page: 1,
        per_page: 2
      ))

      get series_index_path, params: { scholars: [ "Test Scholar" ], per_page: 2 }, headers: headers

      expect(response).to have_http_status(:ok)
      doc = Nokogiri::HTML(response.body)
      page_2_link = doc.at_css('nav[aria-label] a[href*="page=2"]')

      expect(page_2_link).to be_present
      href = page_2_link["href"]
      expect(href).to include("scholars")
      expect(href).to include("per_page=2")
    end

    it "includes search query in pagination links" do
      hits = 3.times.map do |i|
        build_search_hit(type: :series, title: "Series #{i}", scholar_name: "Test Scholar")
      end
      stub_typesense_search(build_search_result(
        hits_by_type: { series: hits },
        total: 3,
        page: 1,
        per_page: 2
      ))

      get series_index_path, params: { q: "test query", per_page: 2 }, headers: headers

      expect(response).to have_http_status(:ok)
      doc = Nokogiri::HTML(response.body)
      page_2_link = doc.at_css('nav[aria-label] a[href*="page=2"]')

      expect(page_2_link).to be_present
      href = page_2_link["href"]
      expect(href).to include("q=")
      expect(href).to include("per_page=2")
    end
  end

  describe "pagination links have turbo_action advance" do
    it "includes data-turbo-action=advance on pagination links" do
      hits = 3.times.map do |i|
        build_search_hit(type: :series, title: "Series #{i}", scholar_name: "Test Scholar")
      end
      stub_typesense_search(build_search_result(
        hits_by_type: { series: hits },
        total: 3,
        page: 1,
        per_page: 2
      ))

      get series_index_path, params: { per_page: 2 }, headers: headers

      expect(response).to have_http_status(:ok)
      doc = Nokogiri::HTML(response.body)
      pagination_links = doc.css('nav[aria-label] a[href*="page="]')

      expect(pagination_links).to be_present
      pagination_links.each do |link|
        expect(link["data-turbo-action"]).to eq("advance")
      end
    end
  end
end
