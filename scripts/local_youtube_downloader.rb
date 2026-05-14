#!/usr/bin/env ruby
# frozen_string_literal: true

# Local YouTube Downloader
# Downloads YouTube videos on your local machine and uploads to server
#
# Setup:
#   1. Install yt-dlp: brew install yt-dlp
#   2. Set environment variables:
#      export ALMAKTABAH_SERVER_URL="https://your-server.com"
#      export ALMAKTABAH_API_TOKEN="your-secret-token"
#   3. Run: ruby local_youtube_downloader.rb
#
# Optional environment variables:
#   DOWNLOAD_DIR: Where to store downloads (default: ~/youtube_downloads)
#   DOWNLOAD_LIMIT: Max videos per run (default: 10)
#   KEEP_FILES: Set to "true" to keep downloaded files after upload

require "net/http"
require "uri"
require "json"
require "fileutils"
require "logger"

class LocalYoutubeDownloader
  DOWNLOAD_DIR = ENV.fetch("DOWNLOAD_DIR", File.expand_path("~/youtube_downloads"))
  SERVER_URL = ENV.fetch("ALMAKTABAH_SERVER_URL") { raise "ALMAKTABAH_SERVER_URL not set" }
  API_TOKEN = ENV.fetch("ALMAKTABAH_API_TOKEN") { raise "ALMAKTABAH_API_TOKEN not set" }
  DOWNLOAD_LIMIT = ENV.fetch("DOWNLOAD_LIMIT", "10").to_i
  KEEP_FILES = ENV.fetch("KEEP_FILES", "false") == "true"

  def initialize
    @logger = Logger.new($stdout)
    @logger.formatter = proc { |severity, datetime, _, msg| "[#{datetime.strftime('%H:%M:%S')}] #{severity}: #{msg}\n" }
    FileUtils.mkdir_p(DOWNLOAD_DIR)
  end

  def run
    @logger.info "Starting YouTube download run..."
    @logger.info "Server: #{SERVER_URL}"
    @logger.info "Download directory: #{DOWNLOAD_DIR}"

    lectures = fetch_pending_lectures
    if lectures.empty?
      @logger.info "No pending lectures to download"
      return
    end

    @logger.info "Found #{lectures.size} lectures to download"

    lectures.each_with_index do |lecture, index|
      @logger.info "[#{index + 1}/#{lectures.size}] Processing: #{lecture['title']}"
      process_lecture(lecture)
    end

    @logger.info "Download run complete!"
  end

  private

  def fetch_pending_lectures
    uri = URI("#{SERVER_URL}/api/lectures/pending_downloads?limit=#{DOWNLOAD_LIMIT}")
    response = make_request(uri, :get)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)["lectures"]
    else
      @logger.error "Failed to fetch pending lectures: #{response.code} #{response.body}"
      []
    end
  end

  def process_lecture(lecture)
    lecture_id = lecture["id"]
    youtube_url = lecture["youtube_url"]

    video_path = download_video(lecture_id, youtube_url)
    return unless video_path

    thumbnail_path = generate_thumbnail(video_path, lecture_id)
    upload_to_server(lecture_id, video_path, thumbnail_path)

    unless KEEP_FILES
      FileUtils.rm_f(video_path)
      FileUtils.rm_f(thumbnail_path) if thumbnail_path
    end
  rescue StandardError => e
    @logger.error "Failed to process lecture #{lecture_id}: #{e.message}"
    @logger.debug e.backtrace.join("\n")
  end

  def download_video(lecture_id, youtube_url)
    output_template = File.join(DOWNLOAD_DIR, "lecture_#{lecture_id}.%(ext)s")

    cmd = [
      "yt-dlp",
      "--no-playlist",
      "-f", "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best",
      "--merge-output-format", "mp4",
      "-o", output_template,
      "--no-warnings",
      "--progress",
      youtube_url
    ]

    @logger.info "Downloading: #{youtube_url}"
    result = system(*cmd)

    unless result
      @logger.error "yt-dlp failed for lecture #{lecture_id}"
      return nil
    end

    # Find the downloaded file
    video_path = Dir.glob(File.join(DOWNLOAD_DIR, "lecture_#{lecture_id}.*")).first
    if video_path && File.exist?(video_path)
      file_size_mb = (File.size(video_path) / 1024.0 / 1024.0).round(2)
      @logger.info "Downloaded: #{File.basename(video_path)} (#{file_size_mb} MB)"
      video_path
    else
      @logger.error "Download completed but file not found for lecture #{lecture_id}"
      nil
    end
  end

  def generate_thumbnail(video_path, lecture_id)
    thumbnail_path = File.join(DOWNLOAD_DIR, "lecture_#{lecture_id}_thumb.jpg")

    cmd = [
      "ffmpeg", "-y",
      "-i", video_path,
      "-ss", "00:00:01",
      "-vframes", "1",
      "-vf", "scale=640:360",
      thumbnail_path
    ]

    result = system(*cmd, out: File::NULL, err: File::NULL)

    if result && File.exist?(thumbnail_path)
      @logger.info "Generated thumbnail: #{File.basename(thumbnail_path)}"
      thumbnail_path
    else
      @logger.warn "Failed to generate thumbnail for lecture #{lecture_id}"
      nil
    end
  end

  def upload_to_server(lecture_id, video_path, thumbnail_path)
    uri = URI("#{SERVER_URL}/api/lectures/#{lecture_id}/upload_video")

    @logger.info "Uploading to server..."

    # Build multipart form data
    boundary = "----RubyFormBoundary#{rand(1_000_000)}"

    body = []
    body << "--#{boundary}\r\n"
    body << "Content-Disposition: form-data; name=\"video\"; filename=\"#{File.basename(video_path)}\"\r\n"
    body << "Content-Type: video/mp4\r\n\r\n"
    body << File.binread(video_path)
    body << "\r\n"

    if thumbnail_path && File.exist?(thumbnail_path)
      body << "--#{boundary}\r\n"
      body << "Content-Disposition: form-data; name=\"thumbnail\"; filename=\"#{File.basename(thumbnail_path)}\"\r\n"
      body << "Content-Type: image/jpeg\r\n\r\n"
      body << File.binread(thumbnail_path)
      body << "\r\n"
    end

    body << "--#{boundary}--\r\n"
    body_str = body.join

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.read_timeout = 600 # 10 minutes for large uploads
    http.open_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{API_TOKEN}"
    request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    request.body = body_str

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      @logger.info "Upload successful for lecture #{lecture_id}"
      true
    else
      @logger.error "Upload failed: #{response.code} #{response.body}"
      false
    end
  end

  def make_request(uri, method)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.read_timeout = 30
    http.open_timeout = 10

    request = case method
    when :get then Net::HTTP::Get.new(uri)
    when :post then Net::HTTP::Post.new(uri)
    end

    request["Authorization"] = "Bearer #{API_TOKEN}"
    request["Content-Type"] = "application/json"

    http.request(request)
  end
end

# Run if executed directly
if __FILE__ == $PROGRAM_NAME
  LocalYoutubeDownloader.new.run
end
