class MediaDurationExtractionJob < ApplicationJob
  queue_as :default

  def perform(media_record)
    return unless media_record.audio.attached? || media_record.video.attached?
    return unless media_record.respond_to?(:duration)
    return if media_record.duration.present?

    extract_duration(media_record)
  end

  private

  def extract_duration(media_record)
    media_file = media_record.video.attached? ? media_record.video : media_record.audio

    media_file.open do |file|
      movie = FFMPEG::Movie.new(file.path)
      if movie.duration
        media_record.update_column(:duration, movie.duration.to_i)
        Rails.logger.info "Duration extracted for #{media_record.class.name} ##{media_record.id}: #{movie.duration.to_i} seconds"
      end
    end
  rescue => e
    Rails.logger.error "Failed to extract duration for #{media_record.class.name} ##{media_record.id}: #{e.message}"
  end
end
