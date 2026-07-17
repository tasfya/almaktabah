require "rails_helper"

# Runs against a real Typesense instance (see spec/support/typesense_integration.rb).
# Exercises the Stimulus filter-reset behaviour: toggling a scholar facet must drop
# the `page` param. The scholar checkboxes come from real facet data, so we index
# articles across two scholars. Previously stubbed and skipped in CI (the in-process
# stub can't reach the browser's separate server process).
RSpec.describe "Filter pagination reset", :typesense, type: :system, js: true do
  let!(:domain) { create(:domain, host: "www.example.com") }

  before do
    scholar_a = create(:scholar, full_name: "Scholar A")
    scholar_b = create(:scholar, full_name: "Scholar B")
    articles = [
      create(:article, title: "Test Article A1", scholar: scholar_a),
      create(:article, title: "Test Article A2", scholar: scholar_a),
      create(:article, title: "Test Article A3", scholar: scholar_a),
      create(:article, title: "Test Article B1", scholar: scholar_b)
    ]
    articles.each { |article| article.update!(domains: [ domain ]) }
    index_records(articles)
  end

  it "resets page parameter when filter checkbox is checked" do
    visit root_path(q: "test", page: 2)

    expect(page.current_url).to include("page=2")

    within("#search_filters_content_desktop") { check "Scholar A" }

    expect(page.current_url).not_to include("page=")
  end

  it "resets page parameter when filter checkbox is unchecked" do
    visit root_path(q: "test", page: 2, scholars: [ "Scholar A" ])

    expect(page.current_url).to include("page=2")

    within("#search_filters_content_desktop") { uncheck "Scholar A" }

    expect(page.current_url).not_to include("page=")
  end
end
