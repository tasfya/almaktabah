require "open-uri"
require "fileutils"
require "streamio-ffmpeg"

class ProcessLessonMediaJob < ApplicationJob
  queue_as :default

  TEMP_DIR = Rails.root.join("tmp", "lesson_processing").freeze
  AUDIO_STORAGE_DIR = Rails.root.join("storage", "audio", "lessons").freeze
  THUMBNAIL_STORAGE_DIR = Rails.root.join("storage", "thumbnails").freeze

  def perform(lesson_id, media_type)
    lesson = Lesson.find(lesson_id)
    Rails.logger.info "Starting to process #{media_type} for lesson #{lesson_id}"

    FileUtils.mkdir_p(TEMP_DIR)
    FileUtils.mkdir_p(AUDIO_STORAGE_DIR)
    FileUtils.mkdir_p(THUMBNAIL_STORAGE_DIR)

    begin
      case media_type
      when "audio"
        process_audio(lesson)
      when "video"
        process_video_file(lesson)
        generate_video_thumbnail(lesson)
      else
        Rails.logger.warn "Unknown media_type '#{media_type}' for lesson #{lesson_id}. No action taken."
        return
      end

      lesson.save! if lesson.changed?

      Rails.logger.info "Successfully processed #{media_type} for lesson #{lesson_id}"
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error "Lesson with ID #{lesson_id} not found. Job aborted."
    rescue FFMPEG::Error => e
      Rails.logger.error "FFmpeg processing failed for #{media_type} for lesson #{lesson_id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise
    rescue StandardError => e
      Rails.logger.error "An unexpected error occurred while processing #{media_type} for lesson #{lesson_id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise
    end
  end

  private

  def process_audio(lesson)
    return unless lesson.audio.attached?

    input_filename = "lesson_#{lesson.id}_#{lesson.audio.filename}"
    input_path = TEMP_DIR.join(input_filename)
    File.write(input_path, lesson.audio.download, mode: "wb")
    Rails.logger.info "Downloaded audio to temporary path: #{input_path}"

    output_path = AUDIO_STORAGE_DIR.join("lesson_#{lesson.id}_optimized.opus")

    optimizer = AudioOptimizer.new(input_path.to_s, output_path.to_s, bitrate: "12k", format: :opus)
    optimizer.optimize
    Rails.logger.info "Audio optimized to: #{output_path}"

    lesson.audio.purge_later if lesson.audio.attached?

    lesson.audio.attach(
      io: File.open(output_path),
      filename: File.basename(output_path),
      content_type: "audio/wav"
    )
    Rails.logger.info "Attached optimized audio to lesson #{lesson.id}"

    extract_duration(lesson, output_path)
  end

  def process_video_file(lesson)
    return unless lesson.video.attached?

    input_filename = "lesson_#{lesson.id}_#{lesson.video.filename}"
    input_path = TEMP_DIR.join(input_filename)
    File.write(input_path, lesson.video.download, mode: "wb")
    Rails.logger.info "Downloaded video to temporary path: #{input_path}"

    unless lesson.audio.attached?
      Rails.logger.info "Converting video to audio for lesson #{lesson.id}"
      audio_output_path = AUDIO_STORAGE_DIR.join("lesson_#{lesson.id}_extracted.wav")

      converter = VideoToAudioConverter.new(input_path.to_s, audio_output_path.to_s)
      converter.convert
      Rails.logger.info "Extracted audio from video to: #{audio_output_path}"

      lesson.audio.purge_later if lesson.audio.attached?
      lesson.audio.attach(
        io: File.open(audio_output_path),
        filename: File.basename(audio_output_path),
        content_type: "audio/wav"
      )
      Rails.logger.info "Attached extracted audio from video for lesson #{lesson.id}"
    end

    extract_duration(lesson, input_path)
  end

  def generate_video_thumbnail(lesson)
    return unless lesson.video.attached?

    input_filename = "lesson_#{lesson.id}_#{lesson.video.filename}"
    video_path = TEMP_DIR.join(input_filename)
    unless File.exist?(video_path)
      File.write(video_path, lesson.video.download, mode: "wb")
      Rails.logger.info "Downloaded video for thumbnail generation to: #{video_path}"
    end

    thumb_output_path = THUMBNAIL_STORAGE_DIR.join("lesson_#{lesson.id}_thumb.jpg")

    begin
      movie = FFMPEG::Movie.new(video_path.to_s)
      capture_time = movie.duration&.positive? ? [ 5, (movie.duration / 2).to_i ].min : 1
      movie.screenshot(thumb_output_path.to_s, seek_time: capture_time, resolution: "320x240", vframes: 1)
      Rails.logger.info "Generated thumbnail at: #{thumb_output_path}"

      lesson.thumbnail.purge_later if lesson.thumbnail.attached?
      lesson.thumbnail.attach(
        io: File.open(thumb_output_path),
        filename: File.basename(thumb_output_path),
        content_type: "image/jpeg"
      )
      Rails.logger.info "Thumbnail generated and attached for lesson #{lesson.id}"
    rescue FFMPEG::Error => e
      Rails.logger.error "Failed to generate thumbnail for lesson #{lesson.id}: #{e.message}"
    end
  end

  def extract_duration(lesson, file_path)
    movie = FFMPEG::Movie.new(file_path.to_s)
    if movie.duration&.positive? && lesson.duration != movie.duration.to_i
      lesson.duration = movie.duration.to_i
      Rails.logger.info "Set duration to #{lesson.duration} seconds for lesson #{lesson.id} from #{file_path}"
    else
      Rails.logger.warn "Could not extract duration or duration is zero for lesson #{lesson.id} from #{file_path}"
    end
  rescue FFMPEG::Error => e
    Rails.logger.warn "FFmpeg error extracting duration for lesson #{lesson.id} from #{file_path}: #{e.message}"
  rescue StandardError => e
    Rails.logger.warn "Unexpected error extracting duration for lesson #{lesson.id} from #{file_path}: #{e.message}"
  end
end
