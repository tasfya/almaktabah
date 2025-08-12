# frozen_string_literal: true

class LectureImportJob < ApplicationJob
  queue_as :default
  include ApplicationHelper
  def perform(row_data, domain_id, line_number = nil)
    Rails.logger.info "Processing lecture import for line #{line_number}"

    row = ::OpenStruct.new(row_data)

    # Find or create scholar
    scholar = Scholar.find(row_data["scholar_id"])

    published_at = parse_datetime(row.published_at)

    lecture = Lecture.find_or_create_by!(
      title: row.title
    ) do |l|
      l.description  = row.description
      l.category     = row.category
      l.scholar      = scholar
      l.youtube_url  = row.youtube_url
      l.published    = published_at.present?
      l.published_at = published_at
    end

    lecture.assign_to(Domain.find(domain_id))

    # Handle file attachments
    attach_from_url(lecture, :thumbnail, row.thumbnail_url, content_type: "image/jpeg") if row.thumbnail_url.present?
    attach_from_url(lecture, :audio, row.audio_file_url, content_type: "audio/mpeg") if row.audio_file_url.present?
    attach_from_url(lecture, :video, row.video_file_url, content_type: "video/mp4") if row.video_file_url.present?

    Rails.logger.info "Successfully created/updated lecture: #{lecture.title}"
    lecture
  rescue => e
    Rails.logger.error "Failed to process lecture import for line #{line_number}: #{e.message}"
    raise e
  end

  private

  def find_or_create_scholar(first_name, last_name)
    return nil if first_name.blank? && last_name.blank?

    Scholar.find_or_create_by!(
      first_name: first_name&.strip,
      last_name: last_name&.strip
    ) do |s|
      s.published = true
      s.published_at = Time.current
    end
  end
end
