# frozen_string_literal: true

require "rails_helper"

# A blob row can outlive its object in the bucket. The page still links to the
# object, the browser gets an error back, and the media element must fall back
# instead of showing a broken image or a dead player.
RSpec.describe "Missing media", type: :system, js: true do
  let!(:domain) { create(:domain, host: "127.0.0.1") }
  let(:scholar) { create(:scholar, full_name: "Abdul Aziz") }

  def delete_object(attachment)
    File.delete(ActiveStorage::Blob.service.path_for(attachment.blob.key))
  end

  def image_loaded?(selector)
    page.evaluate_script("(() => { const i = document.querySelector(#{selector.to_json}); return i.complete && i.naturalWidth > 0 })()")
  end

  it "replaces a news image whose object is gone with the placeholder" do
    news = create(:news, scholar: scholar, published_at: 1.day.ago).tap { |n| n.update!(domains: [ domain ]) }
    delete_object(news.thumbnail)

    visit news_path(scholar, news)

    expect(page).to have_css("article img[src*='media-placeholder']")
    expect(image_loaded?("article img")).to be(true)
  end

  it "replaces a domain logo whose object is gone with the default logo" do
    domain.logo.attach(io: Rails.root.join("spec/files/logo.png").open, filename: "logo.png", content_type: "image/png")
    delete_object(domain.logo)

    news = create(:news, scholar: scholar, published_at: 1.day.ago).tap { |n| n.update!(domains: [ domain ]) }
    visit news_path(scholar, news)

    expect(page).to have_css("header img[src*='/assets/logo']")
    expect(image_loaded?("header img")).to be(true)
  end

  it "hides a lecture video whose object is gone and says it is unavailable" do
    lecture = create(:lecture, scholar: scholar).tap { |l| l.update!(domains: [ domain ]) }
    delete_object(lecture.video)

    visit lecture_path(scholar, lecture, kind: lecture.kind_for_url)

    expect(page).to have_no_css("article video")
    expect(page).to have_text(I18n.t("common.media_unavailable"))
  end

  it "hides an audio player whose object is gone and says it is unavailable" do
    lecture = create(:lecture, scholar: scholar, video: nil).tap { |l| l.update!(domains: [ domain ]) }
    delete_object(lecture.audio)

    visit lecture_path(scholar, lecture, kind: lecture.kind_for_url)
    find("form[data-controller='play-button'] button[data-play-button-target='button']").click

    within("#audio-player") do
      expect(page).to have_text(I18n.t("common.media_unavailable"))
      expect(page).to have_no_css("audio")
    end
  end

  it "shows a notice in the floating player when a lesson video is gone, and recovers for the next video" do
    series = create(:series, title: "Video Series", scholar: scholar).tap { |s| s.update!(domains: [ domain ]) }
    broken = create(:lesson, :with_video, :without_audio, title: "Broken", series: series, position: 1).tap { |l| l.update!(domains: [ domain ]) }
    create(:lesson, :with_video, :without_audio, title: "Working", series: series, position: 2).tap { |l| l.update!(domains: [ domain ]) }
    delete_object(broken.video)

    visit series_path(scholar, series)
    all("[data-controller=video-button]").first.click

    within("#floating-video-player") do
      expect(page).to have_text(I18n.t("common.media_unavailable"))
      expect(page).to have_no_css("video")
    end

    all("[data-controller=video-button]").last.click

    within("#floating-video-player") do
      expect(page).to have_no_text(I18n.t("common.media_unavailable"))
      expect(page).to have_css("video")
    end
  end
end
