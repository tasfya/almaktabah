# frozen_string_literal: true

class YoutubeVideoBatchDownloadJob < ApplicationJob
  queue_as :default

  # @param model [String, nil] 'lecture', 'lesson', or nil for both
  # @param limit [Integer, nil] optional limit on number of records to process
  def perform(model: nil, limit: nil)
    total_count = 0

    if model.nil? || model.to_s.downcase == "lecture"
      total_count += process_model(Lecture, limit: limit)
    end

    if model.nil? || model.to_s.downcase == "lesson"
      total_count += process_model(Lesson, limit: limit)
    end

    Rails.logger.info "YoutubeVideoBatchDownloadJob: Total enqueued #{total_count} download jobs"
    total_count
  end

  private

  def process_model(klass, limit: nil)
    records = klass.with_youtube_url_missing_video
    records = records.limit(limit) if limit.present?

    count = records.count
    Rails.logger.info "YoutubeVideoBatchDownloadJob: Found #{count} #{klass.name.pluralize.downcase} with YouTube URLs but no video attached"

    records.find_each do |record|
      Rails.logger.info "Enqueuing YoutubeDownloadJob for #{klass.name}##{record.id}: #{record.title}"
      YoutubeDownloadJob.perform_later(record)
    end

    count
  end
end
