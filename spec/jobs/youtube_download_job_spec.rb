# frozen_string_literal: true

require "rails_helper"

# Runs the real YoutubeDownloaderService against the fake yt-dlp in
# spec/fixtures/files/fake_bin and real ffmpeg for the thumbnail.
RSpec.describe YoutubeDownloadJob, type: :job do
  let(:video_id) { "dQw4w9WgXcQ" }
  let(:youtube_url) { "https://www.youtube.com/watch?v=#{video_id}" }

  around do |example|
    saved = ENV.to_h
    ENV.update(
      "PATH" => "#{file_fixture('fake_bin')}:/usr/bin:/bin",
      "FAKE_YTDLP_SOURCE" => Rails.root.join("spec/files/test_video.mp4").to_s
    )
    example.run
  ensure
    ENV.replace(saved)
  end

  before do
    stub_request(:get, %r{\Ahttps://www\.youtube\.com/oembed}).to_return(status: 200, body: { title: "محاضرة" }.to_json)
    stub_request(:get, youtube_url).to_return(status: 200, body: "")
  end

  def perform(resource)
    expect { described_class.perform_now(resource) }.to output.to_stdout
  end

  def temp_files
    Dir.glob(described_class::VIDEO_STORAGE_DIR.join("*")) + Dir.glob(described_class::THUMBNAIL_STORAGE_DIR.join("*"))
  end

  it "attaches the downloaded video and a generated thumbnail to a lecture" do
    lecture = create(:lecture, youtube_url: youtube_url, video: nil, thumbnail: nil)

    expect { perform(lecture) }.to have_enqueued_job(CleanupTemporaryFilesJob)
      .with(described_class::VIDEO_STORAGE_DIR.join("Fake Title_#{video_id}.mp4").to_s)

    lecture.reload
    expect(lecture.video.filename.to_s).to eq("Fake Title_#{video_id}.mp4")
    expect(lecture.video.content_type).to eq("video/mp4")
    expect(lecture.thumbnail.filename.to_s).to eq("lecture_#{lecture.id}_thumb.jpg")
    expect(lecture.thumbnail.content_type).to eq("image/jpeg")
    expect(temp_files).to be_empty
  end

  it "keeps an existing thumbnail" do
    lesson = create(:lesson, youtube_url: youtube_url)
    original = lesson.thumbnail.blob

    perform(lesson)

    lesson.reload
    expect(lesson.video).to be_attached
    expect(lesson.thumbnail.blob).to eq(original)
  end

  it "does nothing without a YouTube URL" do
    lecture = create(:lecture, video: nil)

    described_class.perform_now(lecture)

    expect(lecture.reload.video).not_to be_attached
    expect(a_request(:any, /youtube/)).not_to have_been_made
  end

  it "leaves the record without video when yt-dlp is not installed" do
    ENV["PATH"] = "/usr/bin:/bin"
    lecture = create(:lecture, youtube_url: youtube_url, video: nil)

    perform(lecture)

    expect(lecture.reload.video).not_to be_attached
  end

  it "leaves the record without video when the download fails" do
    ENV["FAKE_YTDLP_EXIT"] = "1"
    lecture = create(:lecture, youtube_url: youtube_url, video: nil)

    perform(lecture)

    expect(lecture.reload.video).not_to be_attached
    expect(temp_files).to be_empty
  end
end
