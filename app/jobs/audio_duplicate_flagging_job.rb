class AudioDuplicateFlaggingJob < ApplicationJob
  queue_as :low

  # Process a single record or enqueue jobs for all records of a model type
  # Usage:
  #   AudioDuplicateFlaggingJob.perform_later(lesson) - check single record
  #   AudioDuplicateFlaggingJob.perform_later("Lesson") - enqueue all pending Lessons
  def perform(record_or_model_type)
    if record_or_model_type.is_a?(String)
      enqueue_all_for_model(record_or_model_type)
    else
      check_single_record(record_or_model_type)
    end
  end

  private

  def enqueue_all_for_model(model_type)
    model_class = model_type.constantize
    records = model_class.pending.joins(:audio_attachment)

    Rails.logger.info "Enqueuing #{records.count} #{model_type} records for duplicate checking"

    records.find_each do |record|
      AudioDuplicateFlaggingJob.perform_later(record)
    end
  end

  def check_single_record(record)
    return unless record.audio.attached?
    return unless record.pending?

    Rails.logger.info "Checking #{record.class.name} ##{record.id} for audio duplication"

    service = AudioDeduplicationService.new
    temp_file = Tempfile.new([ "audio_check", ".mp3" ])

    begin
      temp_file.binmode
      temp_file.write(record.audio.download)
      temp_file.rewind

      analysis = service.analyze_file(temp_file.path)

      if analysis[:is_duplicate]
        record.flagged!
        Rails.logger.info "Flagged #{record.class.name} ##{record.id} as potential duplicate " \
                          "(#{analysis[:duration].round}s -> #{analysis[:clean_duration].round}s, #{analysis[:repeat_factor]}x)"
      else
        Rails.logger.info "#{record.class.name} ##{record.id} is not a duplicate"
      end
    ensure
      temp_file.close
      temp_file.unlink
    end
  rescue StandardError => e
    Rails.logger.error "Failed to check #{record.class.name} ##{record.id}: #{e.message}"
    raise
  end
end
