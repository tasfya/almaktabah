# frozen_string_literal: true

require "rails_helper"

# The play button submits a turbo-stream form that fills #audio-player with the
# player partial; the player, collapsible and transcript controllers then wire
# the <audio> element, the panel toggle and the clickable transcript segments.
RSpec.describe "Audio player", type: :system, js: true do
  let!(:domain) { create(:domain, host: "127.0.0.1") }
  let(:scholar) { create(:scholar, full_name: "Abdul Aziz") }
  let(:segments) do
    [
      { start: 0.0, end: 4.0, text: "First segment" },
      { start: 20.0, end: 30.0, text: "Second segment" }
    ]
  end
  let!(:lecture) do
    create(:lecture, title: "Audio Lecture", scholar: scholar, video: nil,
                     transcription_json: { segments: segments }.to_json).tap { |l| l.update!(domains: [ domain ]) }
  end

  let(:player_content) { "#lecture_#{lecture.id}_player_content" }
  let(:audio) { "audio#lecture_#{lecture.id}" }

  def open_player
    visit lecture_path(scholar, lecture, kind: lecture.kind_for_url)
    find("form[data-controller='play-button'] button[data-play-button-target='button']").click
    expect(page).to have_css("#audio-player #{player_content}")
  end

  def audio_property(name)
    page.evaluate_script("document.querySelector('#{audio}').#{name}")
  end

  it "loads the player for the lecture and starts playback" do
    open_player

    within(player_content) { expect(page).to have_css("h4", text: "Audio Lecture") }
    expect(page).to have_css("#{audio}[src]", visible: :all)

    page.document.synchronize do
      raise Capybara::ExpectationNotMet, "audio not playing" if audio_property("paused")
    end
    within("form[data-controller='play-button']") do
      expect(page).to have_css("[data-play-button-target='pauseIcon']:not(.hidden)", visible: :all)
      expect(page).to have_css("[data-play-button-target='playIcon'].hidden", visible: :all)
    end
  end

  it "starts with the details collapsed and toggles them open and closed" do
    open_player

    within(player_content) do
      expect(page).to have_css("[data-collapsible-target='content'].hidden", visible: :all)

      find("[data-collapsible-target='toggleButton']").click
      expect(page).to have_css("[data-collapsible-target='content']:not(.hidden)")
      expect(page).to have_button("Second segment")

      find("[data-collapsible-target='toggleButton']").click
      expect(page).to have_css("[data-collapsible-target='content'].hidden", visible: :all)
    end
  end

  it "seeks the audio to a transcript segment and marks it current" do
    open_player
    within(player_content) do
      find("[data-collapsible-target='toggleButton']").click
      click_button "Second segment"
    end

    page.document.synchronize do
      time = audio_property("currentTime")
      raise Capybara::ExpectationNotMet, "currentTime #{time} not at the segment" unless time.between?(19.9, 29.0)
    end
    expect(page).to have_css("[data-transcript-target='segment'][aria-current='true']", text: "Second segment")
    expect(page).to have_no_css("[data-transcript-target='segment'][aria-current='true']", text: "First segment")
  end

  it "empties the player when it is closed" do
    open_player

    within(player_content) { find("button[title='#{I18n.t('buttons.close')}']").click }

    expect(page).to have_no_css(player_content)
    expect(page.evaluate_script("document.getElementById('audio-player').innerHTML.trim()")).to eq("")
  end
end
