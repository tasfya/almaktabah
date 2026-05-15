#!/usr/bin/env ruby
# frozen_string_literal: true

# Local YouTube Downloader
# Downloads YouTube videos on your local machine and uploads to server
#
# Setup:
#   1. Install yt-dlp: brew install yt-dlp
#   2. Set environment variables:
#      export ALMAKTABAH_SERVER_URL="https://3ilm.org"
#      export ALMAKTABAH_UPLOAD_URL="https://upload.3ilm.org"  # bypasses Cloudflare
#      export ALMAKTABAH_API_TOKEN="your-secret-token"
#   3. Run: ruby local_youtube_downloader.rb
#
# Optional environment variables:
#   DOWNLOAD_DIR: Where to store downloads (default: ~/youtube_downloads)
#   DOWNLOAD_LIMIT: Max videos per run (default: 10)
#   KEEP_FILES: Set to "true" to keep downloaded files after upload
#   ALMAKTABAH_UPLOAD_URL: Separate URL for uploads (bypasses Cloudflare 100MB limit)
#   MODEL: Which model to process - "lecture", "lesson", or "all" (default: "all")

require "net/http"
require "uri"
require "json"
require "fileutils"
require "logger"

class LocalYoutubeDownloader
  DOWNLOAD_DIR = ENV.fetch("DOWNLOAD_DIR", File.expand_path("~/youtube_downloads"))
  SERVER_URL = ENV.fetch("ALMAKTABAH_SERVER_URL") { raise "ALMAKTABAH_SERVER_URL not set" }
  UPLOAD_URL = ENV.fetch("ALMAKTABAH_UPLOAD_URL", SERVER_URL) # Use separate URL to bypass Cloudflare
  API_TOKEN = ENV.fetch("ALMAKTABAH_API_TOKEN") { raise "ALMAKTABAH_API_TOKEN not set" }
  DOWNLOAD_LIMIT = ENV["DOWNLOAD_LIMIT"]&.to_i
  KEEP_FILES = ENV.fetch("KEEP_FILES", "false") == "true"
  MODEL = ENV.fetch("MODEL", "all").downcase # "lecture", "lesson", or "all"

  SUPPORTED_MODELS = %w[lecture lesson].freeze

  def initialize
    @logger = Logger.new($stdout)
    @logger.formatter = proc { |severity, datetime, _, msg| "[#{datetime.strftime('%H:%M:%S')}] #{severity}: #{msg}\n" }
    FileUtils.mkdir_p(DOWNLOAD_DIR)
  end

  def run
    @logger.info "Starting YouTube download run..."
    @logger.info "Server: #{SERVER_URL}"
    @logger.info "Upload: #{UPLOAD_URL}" if UPLOAD_URL != SERVER_URL
    @logger.info "Download directory: #{DOWNLOAD_DIR}"
    @logger.info "Model filter: #{MODEL}"

    models_to_process = MODEL == "all" ? SUPPORTED_MODELS : [ MODEL ]
    total_processed = 0

    models_to_process.each do |model_type|
      total_processed += process_model(model_type)
    end

    if total_processed.zero?
      @logger.info "No pending items to download"
    else
      @logger.info "Download run complete! Processed #{total_processed} items."
    end
  end

  def process_model(model_type)
    @logger.info "--- Processing #{model_type.capitalize}s ---"

    items = fetch_pending_items(model_type)
    if items.empty?
      @logger.info "No pending #{model_type}s to download"
      return 0
    end

    @logger.info "Found #{items.size} #{model_type}s to download"

    items.each_with_index do |item, index|
      @logger.info "[#{index + 1}/#{items.size}] Processing #{model_type}: #{item['title']}"
      process_item(model_type, item)
    end

    items.size
  end

  private

  def fetch_pending_items(model_type)
    url = "#{SERVER_URL}/api/#{model_type}s/pending_downloads"
    url += "?limit=#{DOWNLOAD_LIMIT}" if DOWNLOAD_LIMIT
    uri = URI(url)
    response = make_request(uri, :get)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)["#{model_type}s"]
    else
      @logger.error "Failed to fetch pending #{model_type}s: #{response.code} #{response.body}"
      []
    end
  end

  def process_item(model_type, item)
    item_id = item["id"]
    youtube_url = item["youtube_url"]

    video_path = download_video(model_type, item_id, youtube_url)
    return unless video_path

    thumbnail_path = generate_thumbnail(video_path, model_type, item_id)
    upload_to_server(model_type, item_id, video_path, thumbnail_path)

    unless KEEP_FILES
      FileUtils.rm_f(video_path)
      FileUtils.rm_f(thumbnail_path) if thumbnail_path
    end
  rescue StandardError => e
    @logger.error "Failed to process #{model_type} #{item_id}: #{e.message}"
    @logger.debug e.backtrace.join("\n")
  end

  def download_video(model_type, item_id, youtube_url)
    output_template = File.join(DOWNLOAD_DIR, "#{model_type}_#{item_id}.%(ext)s")

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
      @logger.error "yt-dlp failed for #{model_type} #{item_id}"
      return nil
    end

    # Find the downloaded file
    video_path = Dir.glob(File.join(DOWNLOAD_DIR, "#{model_type}_#{item_id}.*")).first
    if video_path && File.exist?(video_path)
      file_size_mb = (File.size(video_path) / 1024.0 / 1024.0).round(2)
      @logger.info "Downloaded: #{File.basename(video_path)} (#{file_size_mb} MB)"
      video_path
    else
      @logger.error "Download completed but file not found for #{model_type} #{item_id}"
      nil
    end
  end

  def generate_thumbnail(video_path, model_type, item_id)
    thumbnail_path = File.join(DOWNLOAD_DIR, "#{model_type}_#{item_id}_thumb.jpg")

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
      @logger.warn "Failed to generate thumbnail for #{model_type} #{item_id}"
      nil
    end
  end

  def upload_to_server(model_type, item_id, video_path, thumbnail_path)
    uri = URI("#{UPLOAD_URL}/api/#{model_type}s/#{item_id}/upload_video")

    @logger.info "Uploading to #{uri.host}..."

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
      @logger.info "Upload successful for #{model_type} #{item_id}"
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
