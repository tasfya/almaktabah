require "rails_helper"

# Runs against a real Typesense instance (see spec/support/typesense_integration.rb
# for gating and the reset/ensure-collections lifecycle). Earlier this spec stubbed
# the search services in-process, which cannot work in a `js: true` system spec: the
# browser drives the app in a separate process the stub never reaches, so it was
# skipped in CI. Indexing real records instead lets it gate every CI run.
RSpec.describe "Basic Search", :typesense, type: :system, js: true do
  let!(:domain) { create(:domain, host: "www.example.com") }

  it "displays search results" do
    scholar = create(:scholar, full_name: "Scholar Name")
    article = create(:article, title: "Test Article", scholar: scholar)
    article.update!(domains: [ domain ])
    index_records(article)

    visit root_path(q: "Test")

    expect(page).to have_content("Test Article")
  end

  it "shows no results message for empty search" do
    visit root_path(q: "nonexistent")

    expect(page).to have_content(I18n.t("search.index.no_results_title"))
  end
end
