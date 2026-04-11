# frozen_string_literal: true

class PurgeOriginalAudioJob < ApplicationJob
  queue_as :default

  def perform(model_type, record_id)
    model_class = model_type.constantize
    record = model_class.find(record_id)

    return unless record.audio.attached?
    return unless record.final_audio.attached?

    original_duration = extract_duration_from_attachment(record.audio)
    return log_error(record, "Could not extract original audio duration") unless original_duration

    final_duration = extract_duration_from_attachment(record.final_audio)
    return log_error(record, "Could not extract final audio duration") unless final_duration

    duration_diff = (original_duration - final_duration).abs

    if duration_diff <= 1.0
      record.audio.purge
      Rails.logger.info "Purged original audio for #{model_type} ##{record_id} (duration diff: #{duration_diff.round(2)}s)"
    else
      Rails.logger.warn "Duration mismatch for #{model_type} ##{record_id}: original=#{original_duration.round(2)}s, final=#{final_duration.round(2)}s. Keeping original."
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "#{model_type} ##{record_id} not found, skipping"
  rescue => e
    Rails.logger.error "Error purging original audio for #{model_type} ##{record_id}: #{e.message}"
    raise e
  end

  private

  def extract_duration_from_attachment(attachment)
    attachment.open do |file|
      temp = Tempfile.new([ "audio", File.extname(attachment.filename.to_s) ])
      begin
        temp.binmode
        temp.write(file.read)
        temp.rewind
        movie = FFMPEG::Movie.new(temp.path)
        movie.duration
      ensure
        temp.close
        temp.unlink
      end
    end
  rescue => e
    Rails.logger.warn "Failed to extract duration: #{e.message}"
    nil
  end

  def log_error(record, message)
    Rails.logger.error "#{record.class.name} ##{record.id}: #{message}"
  end
end
