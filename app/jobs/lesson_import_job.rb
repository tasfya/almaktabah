# frozen_string_literal: true

require "ostruct"

class LessonImportJob < ApplicationJob
  queue_as :default


  def perform(row_data, domain_id, line_number = nil)
    Rails.logger.info "Processing lesson import for line #{line_number}"

    row = OpenStruct.new(row_data)

    series = find_series(row.series_title) if row.series_title.present?
    published_at = parse_datetime(row.published_at)

    lesson = Lesson.find_or_create_by!(title: row.title) do |l|
      l.description = row.description
      l.category = row.category
      l.content_type = row.content_type.presence || "audio"
      l.series = series
      l.youtube_url = row.youtube_url
      l.position = parse_integer(row.position)
      l.published = published_at.present?
      l.published_at = published_at
    end

    lesson.assign_to(Domain.find(domain_id))

    # Handle file attachments
    attach_from_url(lesson, :thumbnail, row.thumbnail_url) if row.thumbnail_url.present?
    attach_from_url(lesson, :audio, row.audio_file_url) if row.audio_file_url.present?
    attach_from_url(lesson, :video, row.video_file_url) if row.video_file_url.present?

    Rails.logger.info "Successfully created/updated lesson: #{lesson.title}"
    lesson
  rescue => e
    Rails.logger.error "Failed to process lesson import for line #{line_number}: #{e.message}"
    raise e
  end

  private

  def find_series(title)
    return nil if title.blank?
    Series.find_or_create_by!(title: title.strip) do |s|
      s.published = true
      s.published_at = Time.current
    end
  rescue
    nil
  end
end
