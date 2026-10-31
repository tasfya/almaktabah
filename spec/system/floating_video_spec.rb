# frozen_string_literal: true

require "rails_helper"

# A lesson that has a video but no audio gets a watch button on the series page;
# it loads the video into the floating player from the layout, which can be
# minimised and closed.
RSpec.describe "Floating video player", type: :system, js: true do
  let!(:domain) { create(:domain, host: "127.0.0.1") }
  let(:scholar) { create(:scholar, full_name: "Abdul Aziz") }
  let(:series) { create(:series, title: "Video Series", scholar: scholar).tap { |s| s.update!(domains: [ domain ]) } }
  let!(:lesson) do
    create(:lesson, :with_video, :without_audio, title: "Video Lesson", series: series).tap { |l| l.update!(domains: [ domain ]) }
  end

  let(:player) { "#floating-video-player" }

  def open_video
    visit series_path(scholar, series)
    expect(page).to have_no_css(player)
    find("[data-controller='video-button']").click
    expect(page).to have_css(player)
  end

  it "loads the lesson's video into the floating player" do
    open_video

    within(player) do
      expect(page).to have_css("[data-floating-video-target='title']", text: "Video Lesson")
      expect(page).to have_css("video[data-floating-video-target='video']:not(.hidden)")
      expect(page).to have_css("video source[type='video/mp4'][src]", visible: :all)
      expect(page).to have_css("iframe[data-floating-video-target='youtubeIframe'].hidden", visible: :all)
    end
  end

  it "minimises and restores the video" do
    open_video

    within(player) do
      find("[data-floating-video-target='minimizeBtn']", visible: :all).execute_script("this.click()")
      expect(page).to have_css("[data-floating-video-target='videoContainer'].hidden", visible: :all)

      find("[data-floating-video-target='minimizeBtn']", visible: :all).execute_script("this.click()")
      expect(page).to have_css("[data-floating-video-target='videoContainer']:not(.hidden)")
    end
  end

  it "hides the player and stops the video when closed" do
    open_video

    find("#{player} button[data-action='click->floating-video#close']").click

    expect(page).to have_no_css(player)
    expect(page).to have_css("#{player} video.hidden", visible: :all)
    expect(page.evaluate_script("document.querySelector('#{player} video').paused")).to be(true)
  end
end
