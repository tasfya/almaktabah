require "rails_helper"

RSpec.describe "Basic Search", type: :system, js: true do
  before do
    create(:domain, host: "www.example.com")
  end

  it "displays search results" do
    article_hit = build_search_hit(
      type: :article,
      title: "Test Article",
      scholar_name: "Scholar Name"
    )
    stub_typesense_search(build_search_result(
      hits_by_type: { articles: [ article_hit ] },
      total: 1
    ))

    visit root_path(q: "Test")

    expect(page).to have_content("Test Article")
  end

  it "shows no results message for empty search" do
    stub_typesense_search(empty_search_result)

    visit root_path(q: "nonexistent")

    expect(page).to have_content(I18n.t("search.index.no_results_title"))
  end
end
