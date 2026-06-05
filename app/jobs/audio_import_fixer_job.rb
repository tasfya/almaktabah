# frozen_string_literal: true

require "down"
require "ostruct"

class AudioImportFixerJob < ApplicationJob
  queue_as :default

  # Result struct for tracking what happened
  Result = Struct.new(:status, :record, :line_number, :message, :old_duration, :new_duration, keyword_init: true) do
    def fixed? = status == :fixed
    def skipped? = status == :skipped
    def verified? = status == :verified
  end

  # Generous timeouts for large audio files
  DOWNLOAD_OPTIONS = {
    open_timeout: 30,
    read_timeout: 600,       # 10 minutes for large files
    max_size: 500.megabytes,
    max_redirects: 10
  }.freeze

  # Duration difference threshold (in seconds) to trigger a fix
  DURATION_TOLERANCE = 5.0

  def perform(row_data, model_type, domain_id = nil, line_number = nil, force: false)
    @row = OpenStruct.new(row_data)
    @model_type = model_type.to_s.downcase
    @domain_id = domain_id
    @line_number = line_number
    @force = force

    Rails.logger.info "[AudioImportFixer] Processing #{@model_type} for line #{@line_number}"

    return skip("No audio_file_url in row") if @row.audio_file_url.blank?

    @record = find_existing_record
    return skip("Record not found") unless @record

    # Skip if already verified (unless force is true)
    if !@force && @record.audio_verified_at.present?
      return skip("Already verified at #{@record.audio_verified_at}")
    end

    return skip("No audio attached to record") unless @record.audio.attached?

    fix_audio_if_needed(@record)
  rescue => e
    Rails.logger.error "[AudioImportFixer] Failed for line #{@line_number}: #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")
    raise e
  end

  private

  def skip(reason)
    Rails.logger.info "[AudioImportFixer] Skipping line #{@line_number}: #{reason}"
    Result.new(status: :skipped, record: @record, line_number: @line_number, message: reason)
  end

  def find_existing_record
    case @model_type
    when "lecture"
      find_lecture
    when "lesson"
      find_lesson
    when "fatwa"
      find_fatwa
    else
      raise ArgumentError, "Unknown model type: #{@model_type}"
    end
  end

  def find_lecture
    scholar = find_scholar
    return nil unless scholar

    Lecture.find_by(
      title: @row.title,
      category: @row.category,
      scholar_id: scholar.id,
      source_url: @row.source_url,
      kind: @row.kind
    )
  end

  def find_lesson
    scholar = find_scholar
    return nil unless scholar

    series = Series.find_by(title: @row.series_title&.strip, scholar: scholar)
    return nil unless series

    # Match the same logic as LessonImportJob
    Lesson.find_by(
      title: @row.title,
      description: @row.description,
      content_type: @row.content_type.presence || "audio",
      series: series,
      youtube_url: @row.youtube_url,
      source_url: @row.source_url,
      position: @row.position&.to_i
    )
  end

  def find_fatwa
    scholar = find_scholar
    return nil unless scholar

    # Match the same logic as FatwaImportJob
    Fatwa.find_by(
      title: @row.title,
      category: @row.category,
      scholar_id: scholar.id,
      source_url: @row.source_url
    )
  end

  def find_scholar
    if @row.scholar_id.present?
      Scholar.find_by(id: @row.scholar_id)
    elsif @row.scholar_full_name.present?
      Scholar.find_by(full_name: @row.scholar_full_name.strip)
    end
  end

  def fix_audio_if_needed(record)
    # Download fresh copy from source
    Rails.logger.info "[AudioImportFixer] Downloading from #{@row.audio_file_url}"
    downloaded_file = download_audio(@row.audio_file_url)

    # Get durations
    downloaded_duration = extract_duration(downloaded_file.path)
    existing_duration = get_existing_duration(record)

    Rails.logger.info "[AudioImportFixer] Downloaded duration: #{downloaded_duration&.round(2)}s, " \
                      "Existing duration: #{existing_duration&.round(2)}s"

    if durations_match?(downloaded_duration, existing_duration)
      Rails.logger.info "[AudioImportFixer] Durations match, no fix needed for #{record.class}##{record.id}"
      mark_as_verified(record)
      downloaded_file.close
      downloaded_file.unlink if downloaded_file.respond_to?(:unlink)
      return Result.new(
        status: :verified,
        record: record,
        line_number: @line_number,
        message: "Durations match"
      )
    end

    Rails.logger.info "[AudioImportFixer] Duration mismatch detected! Fixing #{record.class}##{record.id}"
    replace_audio(record, downloaded_file, downloaded_duration)
    mark_as_verified(record)

    Result.new(
      status: :fixed,
      record: record,
      line_number: @line_number,
      message: "Duration mismatch fixed",
      old_duration: existing_duration,
      new_duration: downloaded_duration
    )
  ensure
    downloaded_file&.close rescue nil
  end

  def download_audio(url)
    Down.download(url, **DOWNLOAD_OPTIONS)
  rescue Down::Error => e
    Rails.logger.error "[AudioImportFixer] Download failed: #{e.message}"
    raise
  end

  def extract_duration(file_path)
    movie = FFMPEG::Movie.new(file_path)
    movie.duration
  rescue => e
    Rails.logger.warn "[AudioImportFixer] Failed to extract duration: #{e.message}"
    nil
  end

  def get_existing_duration(record)
    # Prefer final_audio if attached, otherwise use audio
    attachment = record.final_audio.attached? ? record.final_audio : record.audio

    attachment.open do |file|
      extract_duration(file.path)
    end
  rescue => e
    Rails.logger.warn "[AudioImportFixer] Failed to get existing duration: #{e.message}"
    nil
  end

  def durations_match?(downloaded_duration, existing_duration)
    return false if downloaded_duration.nil? || existing_duration.nil?

    (downloaded_duration - existing_duration).abs <= DURATION_TOLERANCE
  end

  def replace_audio(record, downloaded_file, downloaded_duration)
    # Purge existing final_audio first (to allow re-optimization)
    if record.final_audio.attached?
      Rails.logger.info "[AudioImportFixer] Purging existing final_audio"
      purge_final_audio_with_blob(record)
    end

    # Purge existing audio
    if record.audio.attached?
      Rails.logger.info "[AudioImportFixer] Purging existing audio"
      record.audio.purge
    end

    # Attach new audio
    downloaded_file.rewind
    filename = derive_filename(@row.audio_file_url, downloaded_file)

    record.audio.attach(
      io: downloaded_file,
      filename: filename,
      content_type: "audio/mpeg"
    )

    # Update duration on record if it has the attribute
    if record.respond_to?(:duration=) && downloaded_duration
      record.update_column(:duration, downloaded_duration.to_i)
    end

    Rails.logger.info "[AudioImportFixer] Successfully replaced audio for #{record.class}##{record.id}"

    # Trigger audio optimization
    Rails.logger.info "[AudioImportFixer] Enqueuing AudioOptimizationJob"
    AudioOptimizationJob.perform_later(record)
  end

  def mark_as_verified(record)
    record.update_column(:audio_verified_at, Time.current)
    Rails.logger.info "[AudioImportFixer] Marked #{record.class}##{record.id} as verified"
  end

  def purge_final_audio_with_blob(record)
    # Need to also delete the blob with the bucket key to allow re-attachment
    key = record.generate_final_audio_bucket_key

    # Delete the blob by key if it exists
    blob = ActiveStorage::Blob.find_by(key: key)
    blob&.purge

    # Also purge the attachment
    record.final_audio.purge if record.final_audio.attached?
  end

  def derive_filename(url, tempfile)
    # Try original filename from Content-Disposition header
    if tempfile.respond_to?(:original_filename) && tempfile.original_filename.present?
      return tempfile.original_filename
    end

    # Fall back to URL basename
    uri = URI.parse(url)
    basename = File.basename(uri.path)
    return basename if basename.present? && basename.include?(".")

    # Generate filename with extension
    ext = if tempfile.respond_to?(:content_type) && tempfile.content_type
      Rack::Mime::MIME_TYPES.invert[tempfile.content_type] || ".mp3"
    else
      ".mp3"
    end

    "audio_#{Time.current.to_i}#{ext}"
  end
end
