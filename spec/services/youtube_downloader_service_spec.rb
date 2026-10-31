# frozen_string_literal: true

require "rails_helper"

# The service shells out to yt-dlp; spec/fixtures/files/fake_bin/yt-dlp stands
# in for it on PATH, so the real command line and process handling run.
RSpec.describe YoutubeDownloaderService do
  let(:video_id) { "dQw4w9WgXcQ" }
  let(:url) { "https://www.youtube.com/watch?v=#{video_id}" }
  let(:download_dir) { Rails.root.join("tmp/spec_youtube_downloads/#{SecureRandom.hex(4)}") }
  let(:args_log) { download_dir.join("args.log") }
  let(:path) { "#{file_fixture('fake_bin')}:/usr/bin:/bin" }
  let(:fake_env) do
    { "PATH" => path, "FAKE_YTDLP_LOG" => args_log.to_s,
      "FAKE_YTDLP_SOURCE" => Rails.root.join("spec/files/test_video.mp4").to_s }
  end

  around do |example|
    saved = ENV.to_h
    example.run
  ensure
    ENV.replace(saved)
    FileUtils.rm_rf(download_dir)
  end

  before do
    ENV.update(fake_env)
    stub_request(:get, %r{\Ahttps://www\.youtube\.com/oembed}).to_return(status: 200, body: { title: "محاضرة" }.to_json)
    stub_request(:get, url).to_return(status: 200, body: '"lengthSeconds":"60"')
  end

  def service(**options)
    described_class.new(url: url, download_path: download_dir, verbose: false, **options)
  end

  def logged_args
    File.readlines(args_log, chomp: true)
  end

  it "creates the download directory" do
    service

    expect(Dir.exist?(download_dir)).to be(true)
  end

  describe "#can_download?" do
    it "is true when yt-dlp is on PATH" do
      expect(service.can_download?).to be(true)
    end

    it "is false when neither yt-dlp nor youtube-dl is on PATH" do
      ENV["PATH"] = "/usr/bin:/bin"

      expect(service.can_download?).to be(false)
    end
  end

  describe "#download" do
    it "runs yt-dlp at 360p and returns the downloaded file" do
      file = service.download

      expect(file).to eq(download_dir.join("Fake Title_#{video_id}.mp4").to_s)
      expect(File.size(file)).to eq(File.size(Rails.root.join("spec/files/test_video.mp4")))
      expect(logged_args).to eq([
        "--format", "bestvideo[height<=360][ext=mp4]+bestaudio[ext=m4a]/best[height<=360]",
        "--merge-output-format", "mp4",
        "--output", download_dir.join("%(title)s_%(id)s.%(ext)s").to_s,
        "--no-playlist", url
      ])
    end

    it "keeps the video info and the parsed progress" do
      downloader = service(verbose: true)

      expect { downloader.download }.to output(/YouTube Downloader Service/).to_stdout
      expect(downloader.download_info).to include("title" => "محاضرة", "duration" => 60, "video_id" => video_id)
      expect(downloader.progress).to include(percentage: 100.0, eta: "00:01")
    end

    {
      "best" => "bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/best[height<=1080]",
      "720p" => "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720]",
      "480p" => "bestvideo[height<=480][ext=mp4]+bestaudio[ext=m4a]/best[height<=480]",
      "worst" => "worstvideo[ext=mp4]+worstaudio[ext=m4a]/worst",
      "18" => "18"
    }.each do |quality, format|
      it "passes --format #{format} for quality #{quality}" do
        service(quality: quality).download

        expect(logged_args.each_cons(2)).to include([ "--format", format ])
      end
    end

    it "returns false when yt-dlp exits with an error" do
      ENV["FAKE_YTDLP_EXIT"] = "1"

      expect(service.download).to be(false)
      expect(Dir.glob(download_dir.join("*.mp4"))).to be_empty
    end

    it "returns false without running yt-dlp when the video info cannot be fetched" do
      stub_request(:get, %r{\Ahttps://www\.youtube\.com/oembed}).to_return(status: 404)

      expect(service.download).to be(false)
      expect(File.exist?(args_log)).to be(false)
    end

    it "falls back to the info only when no tool is installed" do
      ENV["PATH"] = "/usr/bin:/bin"

      expect(service.download).to include("title" => "محاضرة", "embed_url" => "https://www.youtube.com/embed/#{video_id}")
    end

    it "rejects a URL that is not on youtube.com or youtu.be" do
      downloader = described_class.new(url: "https://example.com/watch?v=#{video_id}", download_path: download_dir, verbose: false)

      expect(downloader.download).to be(false)
      expect(File.exist?(args_log)).to be(false)
    end
  end

  describe "#get_available_formats" do
    it "parses yt-dlp's format list, skipping the table header" do
      expect(service.get_available_formats).to eq([
        { format_id: "18", extension: "mp4", resolution: "640x360" },
        { format_id: "140", extension: "m4a", resolution: "audio" }
      ])
      expect(logged_args).to eq([ "--list-formats", url ])
    end

    it "returns an empty list when yt-dlp fails" do
      ENV["FAKE_YTDLP_EXIT"] = "1"

      expect(service.get_available_formats).to eq([])
    end
  end

  describe "#extract_video_id" do
    it "reads the id from watch, short and embed URLs" do
      [ url, "https://youtu.be/#{video_id}", "https://www.youtube.com/embed/#{video_id}" ].each do |link|
        expect(described_class.new(url: link, download_path: download_dir, verbose: false).extract_video_id).to eq(video_id)
      end
    end
  end
end
