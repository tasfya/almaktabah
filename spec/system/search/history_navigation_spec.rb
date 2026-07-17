require "rails_helper"

# Real-Typesense system specs (see spec/support/typesense_integration.rb) covering
# issue #385: browser Back/Forward must stay consistent while searching, filtering
# and paginating. Each filter change has to create a real history entry whose
# server-rendered snapshot (results + checkbox state) matches its URL, so that Back
# undoes exactly one step and Forward redoes it.
#
# The domain host is 127.0.0.1 (the host Capybara's server reports) so `set_domain`
# resolves @domain — required for the content-type filter, which is derived from the
# domain's indexed content types.
RSpec.describe "Search history navigation (#385)", :typesense, type: :system, js: true do
  let!(:domain) { create(:domain, host: "127.0.0.1") }
  let!(:scholar_a) { create(:scholar, full_name: "Scholar A") }
  let!(:scholar_b) { create(:scholar, full_name: "Scholar B") }

  def index_for_domain(*records)
    records.flatten.each { |record| record.update!(domains: [ domain ]) }
    index_records(records.flatten)
  end

  def desktop_filters(&block) = within("#search_filters_content_desktop", &block)

  def query_params = Rack::Utils.parse_nested_query(URI.parse(page.current_url).query.to_s)

  it "home search: a scholar filter is undone by Back and redone by Forward" do
    index_for_domain(
      create(:article, title: "Test Alpha", scholar: scholar_a),
      create(:article, title: "Test Beta", scholar: scholar_b)
    )

    visit root_path(q: "Test")
    expect(page).to have_content("Test Alpha")
    expect(page).to have_content("Test Beta")

    desktop_filters { check "Scholar A" }
    expect(page).to have_content("Test Alpha")
    expect(page).to have_no_content("Test Beta")
    expect(query_params).to have_key("scholars")
    desktop_filters { expect(page).to have_checked_field("Scholar A") }

    page.go_back
    expect(page).to have_content("Test Beta")
    expect(query_params).not_to have_key("scholars")
    desktop_filters { expect(page).to have_unchecked_field("Scholar A") }

    page.go_forward
    expect(page).to have_no_content("Test Beta")
    expect(query_params).to have_key("scholars")
    desktop_filters { expect(page).to have_checked_field("Scholar A") }
  end

  it "home search: a content-type filter is undone by Back and redone by Forward" do
    index_for_domain(
      create(:article, title: "Test Piece", scholar: scholar_a),
      create(:book, title: "Test Volume", scholar: scholar_a)
    )
    book_label = I18n.t("content_types.book")

    visit root_path(q: "Test")
    expect(page).to have_content("Test Piece")
    expect(page).to have_content("Test Volume")

    desktop_filters { check book_label }
    expect(page).to have_content("Test Volume")
    expect(page).to have_no_content("Test Piece")
    expect(query_params).to have_key("content_types")

    page.go_back
    expect(page).to have_content("Test Piece")
    expect(query_params).not_to have_key("content_types")
    desktop_filters { expect(page).to have_unchecked_field(book_label) }

    page.go_forward
    expect(page).to have_no_content("Test Piece")
    expect(query_params).to have_key("content_types")
    desktop_filters { expect(page).to have_checked_field(book_label) }
  end

  it "home browse (no query): a scholar filter is undone by Back and redone by Forward" do
    index_for_domain(
      create(:article, title: "Browse Alpha", scholar: scholar_a),
      create(:article, title: "Browse Beta", scholar: scholar_b)
    )

    visit root_path
    expect(page).to have_content("Browse Alpha")
    expect(page).to have_content("Browse Beta")

    desktop_filters { check "Scholar A" }
    expect(page).to have_content("Browse Alpha")
    expect(page).to have_no_content("Browse Beta")
    expect(query_params).to have_key("scholars")

    page.go_back
    expect(page).to have_content("Browse Beta")
    expect(query_params).not_to have_key("scholars")
    desktop_filters { expect(page).to have_unchecked_field("Scholar A") }

    page.go_forward
    expect(page).to have_no_content("Browse Beta")
    expect(query_params).to have_key("scholars")
    desktop_filters { expect(page).to have_checked_field("Scholar A") }
  end

  it "per-type page: pagination Back/Forward restores the right page (regression guard)" do
    index_for_domain((1..3).map { |i| create(:book, title: "Paged Book #{i}", scholar: scholar_a) })

    visit books_path(per_page: 2)
    expect(page).to have_css(".btn-active", text: "1")

    within("nav.join") { click_link "2" }
    expect(page).to have_css(".btn-active", text: "2")
    expect(query_params["page"]).to eq("2")

    page.go_back
    expect(page).to have_css(".btn-active", text: "1")
    expect(query_params).not_to have_key("page")

    page.go_forward
    expect(page).to have_css(".btn-active", text: "2")
    expect(query_params["page"]).to eq("2")
  end

  it "home search: filter then paginate, Back keeps the filter (page 1), Back again clears it" do
    22.times { |i| create(:article, title: "Testbulk #{i}", scholar: scholar_a).then { index_for_domain(_1) } }
    index_for_domain(create(:article, title: "Testsolo Marker", scholar: scholar_b))

    visit root_path(q: "Test")
    expect(page).to have_content("Testsolo Marker")

    desktop_filters { check "Scholar A" }
    expect(page).to have_no_content("Testsolo Marker")
    expect(page).to have_css(".btn-active", text: "1")

    within("nav.join") { click_link "2" }
    expect(page).to have_css(".btn-active", text: "2")
    expect(query_params["page"]).to eq("2")
    expect(query_params).to have_key("scholars")

    page.go_back
    expect(page).to have_css(".btn-active", text: "1")
    expect(query_params).to have_key("scholars")
    expect(query_params).not_to have_key("page")
    desktop_filters { expect(page).to have_checked_field("Scholar A") }

    page.go_back
    expect(page).to have_content("Testsolo Marker")
    expect(query_params).not_to have_key("scholars")
    desktop_filters { expect(page).to have_unchecked_field("Scholar A") }
  end

  it "home search: two filters in sequence, Back steps through them one at a time" do
    book_label = I18n.t("content_types.book")
    index_for_domain(
      create(:article, title: "Test Doc A", scholar: scholar_a),
      create(:book, title: "Test Tome A", scholar: scholar_a),
      create(:article, title: "Test Doc B", scholar: scholar_b)
    )

    visit root_path(q: "Test")
    expect(page).to have_content("Test Doc A")
    expect(page).to have_content("Test Tome A")
    expect(page).to have_content("Test Doc B")

    desktop_filters { check "Scholar A" }
    expect(page).to have_no_content("Test Doc B")
    expect(page).to have_content("Test Tome A")

    desktop_filters { check book_label }
    expect(page).to have_no_content("Test Doc A")
    expect(page).to have_content("Test Tome A")
    expect(query_params).to have_key("scholars")
    expect(query_params).to have_key("content_types")

    page.go_back
    expect(page).to have_content("Test Doc A")
    expect(query_params).to have_key("scholars")
    expect(query_params).not_to have_key("content_types")
    desktop_filters do
      expect(page).to have_checked_field("Scholar A")
      expect(page).to have_unchecked_field(book_label)
    end

    page.go_back
    expect(page).to have_content("Test Doc B")
    expect(query_params).not_to have_key("scholars")
    desktop_filters { expect(page).to have_unchecked_field("Scholar A") }

    page.go_forward
    expect(page).to have_no_content("Test Doc B")
    expect(query_params).to have_key("scholars")
  end

  it "per-type page (/books): a scholar filter is undone by Back and redone by Forward" do
    index_for_domain(
      create(:book, title: "Book By Aye", scholar: scholar_a),
      create(:book, title: "Book By Bee", scholar: scholar_b)
    )

    visit books_path
    expect(page).to have_content("Book By Aye")
    expect(page).to have_content("Book By Bee")

    desktop_filters { check "Scholar A" }
    expect(page).to have_content("Book By Aye")
    expect(page).to have_no_content("Book By Bee")
    expect(query_params).to have_key("scholars")

    page.go_back
    expect(page).to have_content("Book By Bee")
    expect(query_params).not_to have_key("scholars")
    desktop_filters { expect(page).to have_unchecked_field("Scholar A") }

    page.go_forward
    expect(page).to have_no_content("Book By Bee")
    expect(query_params).to have_key("scholars")
    desktop_filters { expect(page).to have_checked_field("Scholar A") }
  end

  it "mobile drawer: applying a filter creates history, Back restores, and the drawer reopens" do
    page.current_window.resize_to(390, 844)
    index_for_domain(
      create(:article, title: "Mobile Alpha", scholar: scholar_a),
      create(:article, title: "Mobile Beta", scholar: scholar_b)
    )

    visit root_path(q: "Mobile")
    expect(page).to have_content("Mobile Alpha")
    expect(page).to have_content("Mobile Beta")

    find("[data-filter-sidebar-target='toggle']", match: :first).click
    within(:xpath, "//*[@id='search_filters_content_mobile']/ancestor::form[1]") do
      check "Scholar A"
      click_button I18n.t("search.filters.apply")
    end

    expect(page).to have_content("Mobile Alpha")
    expect(page).to have_no_content("Mobile Beta")
    expect(query_params).to have_key("scholars")

    page.go_back
    expect(page).to have_content("Mobile Beta")
    expect(query_params).not_to have_key("scholars")

    # Reopening the drawer proves the daisyUI toggle still works after the frame
    # navigation replaced its elements (the checkboxToggle-listener hazard).
    find("[data-filter-sidebar-target='toggle']", match: :first).click
    within("#search_filters_content_mobile") { expect(page).to have_unchecked_field("Scholar A") }
  end
end
