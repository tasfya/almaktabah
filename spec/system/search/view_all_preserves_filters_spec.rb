require "rails_helper"

# Runs against a real Typesense instance (see spec/support/typesense_integration.rb).
# The home browse screen renders a "View all" link per populated collection; clicking
# it must carry the active scholar filter through to the collection page. Previously
# stubbed and skipped in CI (the in-process stub can't reach the browser's separate
# server process).
RSpec.describe "View all preserves scholar filters", :typesense, type: :system, js: true do
  let!(:domain) { create(:domain, host: "www.example.com") }

  it "preserves scholar filter when clicking View all on home page" do
    scholar_a = create(:scholar, full_name: "Scholar A")
    scholar_b = create(:scholar, full_name: "Scholar B")
    articles = [
      create(:article, title: "Test Article A", scholar: scholar_a),
      create(:article, title: "Test Article B", scholar: scholar_b)
    ]
    articles.each { |article| article.update!(domains: [ domain ]) }
    index_records(articles)

    visit root_path(scholars: [ "Scholar A" ])

    click_link I18n.t("search.view_all")

    expect(page).to have_current_path(articles_path(scholars: [ "Scholar A" ]))
  end
end
