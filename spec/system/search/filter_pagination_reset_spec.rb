require "rails_helper"

# Runs against a real Typesense instance (see spec/support/typesense_integration.rb).
# Exercises the Stimulus filter-reset behaviour: toggling a scholar facet must drop
# the `page` param. The scholar checkboxes come from real facet data, so we index
# articles across two scholars. Previously stubbed and skipped in CI (the in-process
# stub can't reach the browser's separate server process).
#
# Toggling a facet now navigates the `search_content` Turbo frame (issue #385), so
# the URL updates asynchronously — we wait on `have_current_path` rather than reading
# `current_url` synchronously.
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

    expect(page).to have_current_path(/scholars/, url: true)
    expect(page).to have_no_current_path(/[?&]page=/, url: true)
  end

  it "resets page parameter when filter checkbox is unchecked" do
    visit root_path(q: "test", page: 2, scholars: [ "Scholar A" ])

    expect(page.current_url).to include("page=2")

    within("#search_filters_content_desktop") { uncheck "Scholar A" }

    expect(page).to have_no_current_path(/scholars/, url: true)
    expect(page).to have_no_current_path(/[?&]page=/, url: true)
  end
end
