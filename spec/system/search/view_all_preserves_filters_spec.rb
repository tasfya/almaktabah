require "rails_helper"

RSpec.describe "View all preserves scholar filters", type: :system, js: true do
  before do
    create(:domain, host: "www.example.com")
  end

  it "preserves scholar filter when clicking View all on home page" do
    article_hits = [ build_search_hit(type: :article, title: "Test Article", scholar_name: "Scholar A") ]
    stub_typesense_search(build_search_result(
      hits_by_type: { articles: article_hits },
      facets: {
        "scholar_name" => [ { value: "Scholar A", count: 2 }, { value: "Scholar B", count: 1 } ],
        "content_type" => [ { value: "article", count: 1 } ]
      },
      total: 1
    ))

    visit root_path(scholars: [ "Scholar A" ])

    click_link I18n.t("search.view_all")

    expect(page).to have_current_path(articles_path(scholars: [ "Scholar A" ]))
  end
end
