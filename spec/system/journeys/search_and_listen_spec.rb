# frozen_string_literal: true

require "rails_helper"

# A visitor types a query in the header search box, narrows it to lectures with
# the content-type menu, plays a result from its card and opens it. The other
# search specs start from a URL with ?q= already set, so none of them goes
# through the header form and its search-navbar controller.
#
# The domain host is 127.0.0.1, the host Capybara's server reports, so the
# content-type menu is built from this domain's indexed types.
RSpec.describe "Journey: search from the header and listen", :typesense, type: :system, js: true do
  let!(:domain) { create(:domain, host: "127.0.0.1") }
  let(:scholar) { create(:scholar, full_name: "Abdul Aziz") }
  let!(:lecture) do
    create(:lecture, title: "Tawhid Lecture", scholar: scholar, video: nil).tap { |l| l.update!(domains: [ domain ]) }
  end

  before do
    book = create(:book, title: "Tawhid Book", scholar: scholar).tap { |b| b.update!(domains: [ domain ]) }
    index_records(lecture, book)
  end

  def header_search = find("form[data-controller='search-navbar']", match: :first)

  def audio_playing?
    page.evaluate_script("(() => { const a = document.querySelector('audio#lecture_#{lecture.id}'); return !!a && !a.paused })()")
  end

  it "searches, narrows to lectures, plays a result and opens it" do
    visit about_path

    within(header_search) do
      fill_in "q", with: "Tawhid"
      find("button[type='submit']").click
    end

    expect(page).to have_current_path(root_path(q: "Tawhid"))
    expect(page).to have_link("Tawhid Lecture")
    expect(page).to have_link("Tawhid Book")

    within(header_search) { find("select").select(I18n.t("navigation.lectures")) }

    expect(page).to have_current_path(lectures_path(q: "Tawhid"))
    expect(page).to have_link("Tawhid Lecture")
    expect(page).to have_no_link("Tawhid Book")

    find("form[action='#{play_path(resource_type: 'lecture', id: lecture.id)}'] button[type='submit']").click
    expect(page).to have_css("#audio-player #lecture_#{lecture.id}_player_content")
    page.document.synchronize do
      raise Capybara::ExpectationNotMet, "audio not playing" unless audio_playing?
    end

    click_link "Tawhid Lecture"

    expect(page).to have_current_path(lecture_path(scholar, lecture, kind: lecture.kind_for_url))
    expect(page).to have_css("h1", text: "Tawhid Lecture")
  end
end
