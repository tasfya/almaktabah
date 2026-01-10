require "rails_helper"

RSpec.describe "Filter pagination reset", type: :system, js: true do
  before do
    create(:domain, host: "www.example.com")
  end

  it "resets page parameter when filter checkbox is checked" do
    hits = 3.times.map { |i| build_search_hit(type: :article, title: "Article #{i}", scholar_name: "Scholar A") }
    stub_typesense_search(build_search_result(
      hits_by_type: { articles: hits },
      facets: {
        "scholar_name" => [ { value: "Scholar A", count: 2 }, { value: "Scholar B", count: 1 } ],
        "content_type" => [ { value: "article", count: 3 } ]
      },
      total: 3
    ))

    visit root_path(q: "test", page: 2)

    expect(page.current_url).to include("page=2")

    within("#search_filters_content_desktop") { check "Scholar A" }

    expect(page.current_url).not_to include("page=")
  end

  it "resets page parameter when filter checkbox is unchecked" do
    hits = 3.times.map { |i| build_search_hit(type: :article, title: "Article #{i}", scholar_name: "Scholar A") }
    stub_typesense_search(build_search_result(
      hits_by_type: { articles: hits },
      facets: {
        "scholar_name" => [ { value: "Scholar A", count: 2 }, { value: "Scholar B", count: 1 } ],
        "content_type" => [ { value: "article", count: 3 } ]
      },
      total: 3
    ))

    visit root_path(q: "test", page: 2, scholars: [ "Scholar A" ])

    expect(page.current_url).to include("page=2")

    within("#search_filters_content_desktop") { uncheck "Scholar A" }

    expect(page.current_url).not_to include("page=")
  end
end
