# frozen_string_literal: true

class VideoBatchProcessingJob < ApplicationJob
  queue_as :default

  # Processes videos that have video attached but missing audio
  # Extracts audio from video and generates thumbnail
  #
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

    Rails.logger.info "VideoBatchProcessingJob: Total enqueued #{total_count} processing jobs"
    total_count
  end

  private

  def process_model(klass, limit: nil)
    records = klass.joins(:video_attachment).where.missing(:audio_attachment)
    records = records.limit(limit) if limit.present?

    count = records.count
    Rails.logger.info "VideoBatchProcessingJob: Found #{count} #{klass.name.pluralize.downcase} with video but no audio"

    records.find_each do |record|
      Rails.logger.info "Enqueuing VideoProcessingJob for #{klass.name}##{record.id}: #{record.title}"
      VideoProcessingJob.perform_later(record)
    end

    count
  end
end
