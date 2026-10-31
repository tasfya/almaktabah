# frozen_string_literal: true

require "rails_helper"

# Indexes real series so the pagination links come from a real page count:
# three records at per_page=2 must render a link to page 2.
RSpec.describe "Pagination", :typesense, type: :request do
  include_context "with tenant domain"

  let(:tenant_host) { "www.example.com" }
  let(:scholar) { create(:scholar, full_name: "Test Scholar") }

  before do
    series = Array.new(3) { |i| create(:series, title: "Series #{i}", scholar: scholar) }
    series.each { |s| s.update!(domains: [ domain ]) }
    index_records(series)
  end

  def page_2_link
    html.at_css('nav[aria-label] a[href*="page=2"]')
  end

  def link_params(link)
    Rack::Utils.parse_nested_query(URI.parse(link["href"]).query)
  end

  describe "pagination links preserve query parameters" do
    it "includes scholar filter in pagination links" do
      get series_index_path, params: { scholars: [ "Test Scholar" ], per_page: 2 }

      expect(response).to have_http_status(:ok)
      expect(page_2_link).to be_present
      expect(link_params(page_2_link)).to include("scholars" => [ "Test Scholar" ], "per_page" => "2", "page" => "2")
    end

    it "includes search query in pagination links" do
      get series_index_path, params: { q: "Series", per_page: 2 }

      expect(response).to have_http_status(:ok)
      expect(page_2_link).to be_present
      expect(link_params(page_2_link)).to include("q" => "Series", "per_page" => "2", "page" => "2")
    end
  end

  describe "pagination links have turbo_action advance" do
    it "includes data-turbo-action=advance on pagination links" do
      get series_index_path, params: { per_page: 2 }

      expect(response).to have_http_status(:ok)
      pagination_links = html.css('nav[aria-label] a[href*="page="]')

      expect(pagination_links).to be_present
      expect(pagination_links.map { |link| link["data-turbo-action"] }).to all(eq("advance"))
    end
  end

  it "renders no page 2 link when everything fits on one page" do
    get series_index_path, params: { per_page: 3 }

    expect(response).to have_http_status(:ok)
    expect(page_2_link).to be_nil
  end
end
