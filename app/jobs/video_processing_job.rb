require "fileutils"
require "streamio-ffmpeg"
require "securerandom"

class AudioVideoDurationMismatchError < StandardError; end

class VideoProcessingJob < ApplicationJob
  queue_as :default

  TEMP_DIR = Rails.root.join("tmp", "video_processing").freeze
  AUDIO_STORAGE_DIR = Rails.root.join("tmp", "audio", "items").freeze
  THUMBNAIL_STORAGE_DIR = Rails.root.join("tmp", "thumbnails").freeze

  def perform(item)
    return unless item.video?
    return if item.audio.attached? && item.thumbnail.attached?

    FileUtils.mkdir_p(TEMP_DIR)
    FileUtils.mkdir_p(AUDIO_STORAGE_DIR)
    FileUtils.mkdir_p(THUMBNAIL_STORAGE_DIR)

    timestamp = Time.now.to_i
    unique_id = SecureRandom.hex(4)

    input_path = nil
    audio_output_path = nil
    thumbnail_output_path = nil

    begin
      safe_filename = item.video.filename.to_s.gsub(/[^a-zA-Z0-9\.\-_]/, "_")
      base_name = "item_#{item.id}_#{timestamp}_#{unique_id}_#{safe_filename}"
      input_path = TEMP_DIR.join(base_name)

      # Stream video to file instead of loading into memory
      File.open(input_path, "wb") do |file|
        item.video.download { |chunk| file.write(chunk) }
      end
      Rails.logger.info "Downloaded video to temporary path: #{input_path}"

      if !item.audio.attached?
        Rails.logger.info "Extracting audio from video for item #{item.id}"

        model_type = item.class.name.downcase
        audio_output_filename = "#{model_type}_#{item.id}.mp3"
        audio_output_path = AUDIO_STORAGE_DIR.join("#{model_type}_#{item.id}_#{timestamp}.mp3")

        converter = VideoToAudioConverter.new(
          input_path.to_s,
          audio_output_path.to_s
        )
        converter.convert
        Rails.logger.info "Extracted audio to: #{audio_output_path}"

        # Verify audio duration matches video duration before attaching
        video_duration = FFMPEG::Movie.new(input_path.to_s).duration
        audio_duration = FFMPEG::Movie.new(audio_output_path.to_s).duration
        duration_diff = (video_duration - audio_duration).abs

        if duration_diff > 2.0
          raise AudioVideoDurationMismatchError, "Audio duration (#{audio_duration.round(1)}s) doesn't match video duration (#{video_duration.round(1)}s) for #{item.class.name} ID #{item.id}. Diff: #{duration_diff.round(1)}s"
        end

        Rails.logger.info "Duration verified: video=#{video_duration.round(1)}s, audio=#{audio_duration.round(1)}s"

        # Use File.open to stream instead of loading into memory
        File.open(audio_output_path, "rb") do |file|
          item.audio.attach(
            io: file,
            filename: audio_output_filename,
            content_type: "audio/mpeg"
          )
        end
        AudioOptimizationJob.perform_later(item) if item.audio.attached?
        Rails.logger.info "Attached extracted audio for item #{item.id}"
      end

      if !item.thumbnail.attached?
        Rails.logger.info "Generating thumbnail for item #{item.id}"
        movie = FFMPEG::Movie.new(input_path.to_s)
        thumbnail_output_filename = "thumb_#{item.id}_#{timestamp}_#{unique_id}.jpg"
        thumbnail_output_path = THUMBNAIL_STORAGE_DIR.join(thumbnail_output_filename)

        movie.screenshot(thumbnail_output_path.to_s, seek_time: 0, resolution: "640x360")
        File.open(thumbnail_output_path, "rb") do |file|
          item.thumbnail.attach(
            io: file,
            filename: thumbnail_output_filename,
            content_type: "image/jpeg"
          )
        end
        Rails.logger.info "Attached thumbnail for item #{item.id}"
      end

    rescue => e
      Rails.logger.error "Video processing failed for item ID #{item.id}: #{e.message} #{e.backtrace.join("\n")}"
    ensure
      FileUtils.rm_f(input_path) if input_path && File.exist?(input_path)
      FileUtils.rm_f(audio_output_path) if audio_output_path && File.exist?(audio_output_path)
      FileUtils.rm_f(thumbnail_output_path) if thumbnail_output_path && File.exist?(thumbnail_output_path)
    end
  end
end
