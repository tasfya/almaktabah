require "open-uri"
require "fileutils"
require "streamio-ffmpeg"
require "securerandom"

class AudioOptimizationJob < ApplicationJob
  queue_as :default

  TEMP_DIR = Rails.root.join("tmp", "audio_processing").freeze
  AUDIO_STORAGE_DIR = Rails.root.join("storage", "audio").freeze

  def perform(item)
    return unless item.audio?
    return if item.optimized_audio.attached?

    FileUtils.mkdir_p(TEMP_DIR)
    FileUtils.mkdir_p(AUDIO_STORAGE_DIR)

    timestamp = Time.now.to_i
    unique_id = SecureRandom.hex(4)

    input_path = nil
    optimized_path = nil

    begin
      item.audio.open do |audio_file|
        input_path = write_temp_file(item, audio_file, timestamp, unique_id)
        optimized_path = optimize_audio(input_path, timestamp, unique_id)

        optimized_file_binary = File.binread(optimized_path)
        optimized_filename = File.basename(optimized_path)

        item.optimized_audio.attach(
          io: StringIO.new(optimized_file_binary),
          filename: optimized_filename,
          content_type: "audio/opus"
        )

        item.save!
      end
    rescue => e
      Rails.logger.error "Audio optimization failed for item ID #{item.id}: #{e.message}"
    ensure
      FileUtils.rm_f(input_path) if input_path && File.exist?(input_path)
      FileUtils.rm_f(optimized_path) if optimized_path && File.exist?(optimized_path)
    end
  end

  private

  def write_temp_file(item, audio_file, timestamp, unique_id)
    safe_name = item.audio.filename.to_s.gsub(/[^a-zA-Z0-9\.\-_]/, "_")
    input_filename = "#{item.class.name.underscore}_#{item.id}_#{timestamp}_#{unique_id}_#{safe_name}"
    input_path = TEMP_DIR.join(input_filename)
    File.write(input_path, audio_file.read, mode: "wb")
    input_path
  end

  def optimize_audio(input_path, timestamp, unique_id)
    base = File.basename(input_path, ".*")
    output_filename = "op_#{base}_#{timestamp}_#{unique_id}.opus"
    output_path = AUDIO_STORAGE_DIR.join(output_filename)

    optimizer = AudioOptimizer.new(input_path.to_s, output_path.to_s, bitrate: "12k", format: :opus)
    optimizer.optimize

    output_path
  end
end
