# frozen_string_literal: true

class PurgeOriginalAudioBatchJob < ApplicationJob
  queue_as :default

  BATCH_LIMIT = 50

  def perform(model_type: nil, dry_run: false)
    @dry_run = dry_run
    @stats = { checked: 0, purged: 0, skipped: 0, errors: 0 }

    Rails.logger.info "Starting purge original audio batch job (dry_run: #{dry_run})..."

    models = model_type ? [ model_type.constantize ] : [ Lecture, Lesson, Fatwa ]

    models.each do |klass|
      process_model(klass)
    end

    log_summary
  end

  private

  def process_model(klass)
    Rails.logger.info "Processing #{klass.name}..."

    records = klass
      .joins(:audio_attachment)
      .joins(:final_audio_attachment)
      .limit(BATCH_LIMIT)

    records.find_each do |record|
      process_record(record)
    end
  end

  def process_record(record)
    @stats[:checked] += 1

    original_duration = extract_duration(record.audio)
    unless original_duration
      Rails.logger.warn "#{record.class.name}##{record.id}: Could not extract original audio duration"
      @stats[:skipped] += 1
      return
    end

    final_duration = extract_duration(record.final_audio)
    unless final_duration
      Rails.logger.warn "#{record.class.name}##{record.id}: Could not extract final audio duration"
      @stats[:skipped] += 1
      return
    end

    duration_diff = (original_duration - final_duration).abs

    if duration_diff <= 1.0
      if @dry_run
        Rails.logger.info "[DRY RUN] Would purge original audio for #{record.class.name}##{record.id} (diff: #{duration_diff.round(2)}s)"
      else
        record.audio.purge
        Rails.logger.info "Purged original audio for #{record.class.name}##{record.id} (diff: #{duration_diff.round(2)}s)"
      end
      @stats[:purged] += 1
    else
      Rails.logger.warn "#{record.class.name}##{record.id}: Duration mismatch - original=#{original_duration.round(2)}s, final=#{final_duration.round(2)}s. Keeping original."
      @stats[:skipped] += 1
    end
  rescue => e
    Rails.logger.error "#{record.class.name}##{record.id}: Error - #{e.message}"
    @stats[:errors] += 1
  end

  def extract_duration(attachment)
    attachment.open do |file|
      movie = FFMPEG::Movie.new(file.path)
      movie.duration
    end
  rescue => e
    Rails.logger.warn "Failed to extract duration: #{e.message}"
    nil
  end

  def log_summary
    Rails.logger.info "=" * 50
    Rails.logger.info "Purge Original Audio Batch Job Summary"
    Rails.logger.info "=" * 50
    Rails.logger.info "Checked: #{@stats[:checked]}"
    Rails.logger.info "Purged:  #{@stats[:purged]}"
    Rails.logger.info "Skipped: #{@stats[:skipped]}"
    Rails.logger.info "Errors:  #{@stats[:errors]}"
    Rails.logger.info "Dry run: #{@dry_run}"
    Rails.logger.info "=" * 50
  end
end
