class YoutubeDownloadJob < ApplicationJob
  queue_as :default

  def perform(record_type, record_id, download_type = "video")
    @record = record_type.constantize.find(record_id)
    @download_type = download_type

    return unless @record.youtube_url.present?

    Rails.logger.info "Starting YouTube processing for #{record_type} #{record_id}: #{@record.youtube_url}"

    downloader = YoutubeDownloaderService.new(
      url: @record.youtube_url,
      download_path: storage_path,
      format: download_format
    )

    # First, get video info and update record
    video_info = downloader.get_video_info
    if video_info
      update_record_with_info(video_info)
      Rails.logger.info "Updated #{record_type} #{record_id} with YouTube video info"
    end

    # Try to download if external tools are available
    if downloader.can_download?
      downloaded_file = case @download_type
      when "audio"
                         downloader.download_audio_only
      else
                         downloader.download
      end

      if downloaded_file.is_a?(String) && File.exist?(downloaded_file)
        attach_downloaded_file(downloaded_file)
        Rails.logger.info "Successfully downloaded and attached file for #{record_type} #{record_id}"
      else
        Rails.logger.info "Download completed but no file to attach for #{record_type} #{record_id}"
      end
    else
      Rails.logger.warn "External download tools not available. Only extracted video info."
      Rails.logger.warn "To enable downloading: #{downloader.installation_suggestion}"
    end

  rescue StandardError => e
    Rails.logger.error "YouTube processing job failed for #{record_type} #{record_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  private

  def download_with_external_tools
    output_path = File.join(storage_path, "%(title)s.%(ext)s")
    format = @download_type == "audio" ? "mp3" : "mp4"

    YoutubeDownloaderService.download_with_external_tool(
      @record.youtube_url,
      output_path,
      format: format
    )
  end

  def storage_path
    case @record.class.name.downcase
    when "lesson"
      Rails.root.join("storage", "youtube", "lessons")
    when "lecture"
      Rails.root.join("storage", "youtube", "lectures")
    else
      Rails.root.join("storage", "youtube", "downloads")
    end
  end

  def download_format
    @download_type == "audio" ? "mp3" : "mp4"
  end

  def update_record_with_info(video_info)
    return unless video_info.is_a?(Hash)

    # Update duration if available and not already set
    if video_info["duration"] && (!@record.duration || @record.duration.zero?)
      @record.update_column(:duration, video_info["duration"].to_i)
    end

    # Update title if empty (optional) - handle encoding properly
    if video_info["title"] && @record.title.blank?
      title = safe_encode_text(video_info["title"])
      @record.update_column(:title, title) if title
    end

    # Update description if empty (optional) - handle encoding properly
    if video_info["description"] && @record.description.blank?
      description = safe_encode_text(video_info["description"].to_s.truncate(500))
      @record.update_column(:description, description) if description
    end
  end

  # Helper method to safely handle text encoding
  def safe_encode_text(text)
    return nil unless text.present?

    text_str = text.to_s

    # If it's already valid UTF-8, return as is
    if text_str.encoding == Encoding::UTF_8 && text_str.valid_encoding?
      return text_str
    end

    # Try different encoding approaches
    begin
      # First, try to detect if it's actually UTF-8 with wrong encoding label
      if text_str.encoding == Encoding::ASCII_8BIT
        utf8_attempt = text_str.force_encoding("UTF-8")
        return utf8_attempt if utf8_attempt.valid_encoding?
      end

      # Convert to UTF-8 with replacement characters for invalid bytes
      text_str.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
    rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError => e
      Rails.logger.warn "Encoding issue with text: #{e.message}"
      # Fallback: scrub invalid characters
      text_str.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?").scrub("?")
    rescue => e
      Rails.logger.warn "Unexpected encoding error: #{e.message}"
      # Last resort: use only ASCII characters
      text_str.gsub(/[^\x00-\x7F]/, "?")
    end
  end

  def attach_downloaded_file(file_path)
    return unless File.exist?(file_path)

    file_extension = File.extname(file_path).downcase

    case file_extension
    when ".mp3"
      attach_audio_file(file_path)
    when ".mp4", ".webm", ".mkv"
      attach_video_file(file_path)
    end
  end

  def attach_audio_file(file_path)
    return unless @record.respond_to?(:audio)

    @record.audio.purge_later if @record.audio.attached?
    @record.audio.attach(
      io: File.open(file_path),
      filename: File.basename(file_path),
      content_type: "audio/mpeg"
    )

    Rails.logger.info "Attached audio file for #{@record.class.name} #{@record.id}"
  end

  def attach_video_file(file_path)
    return unless @record.respond_to?(:video)

    @record.video.purge_later if @record.video.attached?
    @record.video.attach(
      io: File.open(file_path),
      filename: File.basename(file_path),
      content_type: content_type_for_file(file_path)
    )

    Rails.logger.info "Attached video file for #{@record.class.name} #{@record.id}"
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
end
