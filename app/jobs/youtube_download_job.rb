require "open-uri"
require "fileutils"
require "streamio-ffmpeg"

class YoutubeDownloadJob < ApplicationJob
  queue_as :default

  TEMP_DIR = Rails.root.join("tmp", "youtube_downloads").freeze
  VIDEO_STORAGE_DIR = Rails.root.join("tmp", "youtube", "videos").freeze
  THUMBNAIL_STORAGE_DIR = Rails.root.join("tmp", "thumbnails").freeze

  def perform(resource, file_url:)
    @resource = resource
    @file_url = file_url

    return unless @resource.youtube_url.present?

    setup_directories

    begin
      Rails.logger.info "Starting YouTube video processing for #{resource_name}: #{@file_url}"

      downloader = YoutubeDownloaderService.new(
        url: @file_url,
        download_path: VIDEO_STORAGE_DIR,
        format: "mp4"
      )

      video_info = downloader.get_video_info
      if video_info
        update_resource_with_info(video_info)
        Rails.logger.info "Updated #{resource_name} with YouTube video info"
      end

      if downloader.can_download?
        downloaded_file = downloader.download
        if downloaded_file.is_a?(String) && File.exist?(downloaded_file)
          attach_downloaded_file(downloaded_file)
          process_thumbnail(downloaded_file) unless @resource.thumbnail.attached?
          extract_duration(downloaded_file)
          Rails.logger.info "Successfully downloaded and processed video for #{resource_name}"
        else
          Rails.logger.info "Download completed but no file to attach for #{resource_name}"
        end
      else
        Rails.logger.warn "External download tools not available for #{resource_name}. Only extracted video info."
        Rails.logger.warn "To enable downloading: #{downloader.installation_suggestion}"
      end

      @resource.save! if @resource.changed?

    rescue StandardError => e
      Rails.logger.error "YouTube video processing failed for #{resource_name}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise
    ensure
      cleanup_temp_files
    end
  end

  private

  def setup_directories
    FileUtils.mkdir_p(TEMP_DIR)
    FileUtils.mkdir_p(VIDEO_STORAGE_DIR)
    FileUtils.mkdir_p(THUMBNAIL_STORAGE_DIR)
  end

  def download_file
    temp_filename = "#{resource_name}_#{Time.current.to_i}_download.mp4"
    temp_path = TEMP_DIR.join(temp_filename)

    downloaded_path = ApplicationJob.download_file(@file_url, temp_path.to_s)

    if downloaded_path
      Rails.logger.info "Downloaded video to: #{downloaded_path}"
      downloaded_path
    else
      Rails.logger.error "Failed to download video from: #{@file_url}"
      nil
    end
  end

  def attach_downloaded_file(file_path)
    return unless File.exist?(file_path) && @resource.respond_to?(:video)

    @resource.video.purge_later if @resource.video.attached?
    @resource.video.attach(
      io: File.open(file_path),
      filename: File.basename(file_path),
      content_type: content_type_for_file(file_path)
    )
    Rails.logger.info "Attached video file for #{resource_name}"
  end

  def process_thumbnail(file_path)
    thumbnail_output_filename = "#{resource_name}_thumb.jpg"
    thumbnail_output_path = THUMBNAIL_STORAGE_DIR.join(thumbnail_output_filename)

    movie = FFMPEG::Movie.new(file_path)
    movie.screenshot(thumbnail_output_path.to_s, seek_time: 0, resolution: "640x360")
    Rails.logger.info "Generated thumbnail to: #{thumbnail_output_path}"

    @resource.thumbnail.attach(
      io: File.open(thumbnail_output_path),
      filename: thumbnail_output_filename,
      content_type: "image/jpeg"
    )
    Rails.logger.info "Attached thumbnail for #{resource_name}"
  end

  def extract_duration(file_path)
    movie = FFMPEG::Movie.new(file_path)

    if movie.duration&.positive? && @resource.duration != movie.duration.to_i
      @resource.duration = movie.duration.to_i
      Rails.logger.info "Set duration to #{@resource.duration} seconds for #{resource_name}"
    end
  rescue FFMPEG::Error => e
    Rails.logger.warn "FFmpeg error extracting duration for #{resource_name}: #{e.message}"
  rescue => e
    Rails.logger.warn "Error extracting duration for #{resource_name}: #{e.message}"
  end

  def content_type_for_file(file_path)
    case File.extname(file_path).downcase
    when ".mp4"
      "video/mp4"
    when ".webm"
      "video/webm"
    when ".mkv"
      "video/x-matroska"
    else
      "application/octet-stream"
    end
  end

  def resource_name
    "#{@resource.class.name.downcase}_#{@resource.id}"
  end

  def cleanup_temp_files
    Dir.glob(TEMP_DIR.join("*")).each do |file|
      FileUtils.rm_f(file)
    end
    Dir.glob(VIDEO_STORAGE_DIR.join("*")).each do |file|
      FileUtils.rm_f(file)
    end
    Dir.glob(THUMBNAIL_STORAGE_DIR.join("*")).each do |file|
      FileUtils.rm_f(file)
    end
    Rails.logger.info "Cleaned up temp files for #{resource_name}"
  end
end
