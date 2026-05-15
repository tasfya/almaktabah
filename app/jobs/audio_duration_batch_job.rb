class AudioDurationBatchJob < ApplicationJob
  queue_as :ffmpeg_queue

  BATCH_LIMIT = 50

  def perform
    Rails.logger.info "Starting audio duration batch update..."

    total_processed = 0

    [ Lecture, Lesson, Fatwa ].each do |klass|
      processed = process_model(klass)
      total_processed += processed
    end

    Rails.logger.info "Audio duration batch update complete. Processed #{total_processed} records."
  end

  private

  def process_model(klass)
    # Find records with audio but no duration
    records = klass
      .where(duration: [ nil, 0 ])
      .joins(:final_audio_attachment)
      .limit(BATCH_LIMIT)

    count = 0
    records.find_each do |record|
      extract_duration(record)
      count += 1
    end

    Rails.logger.info "Processed #{count} #{klass.name.pluralize} for duration extraction"
    count
  end

  def extract_duration(record)
    audio = record.final_audio

    audio.open do |file|
      movie = FFMPEG::Movie.new(file.path)
      if movie.duration && movie.duration > 0
        record.update_column(:duration, movie.duration.to_i)
        Rails.logger.info "Duration set for #{record.class.name}##{record.id}: #{movie.duration.to_i}s"
      end
    end
  rescue => e
    Rails.logger.error "Failed to extract duration for #{record.class.name}##{record.id}: #{e.message}"
  end
end
