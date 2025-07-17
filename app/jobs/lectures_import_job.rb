# frozen_string_literal: true

class LecturesImportJob < ApplicationJob
  queue_as :imports

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(row_data, domain_id, line_number = nil)
    Rails.logger.info "Processing lecture import for line #{line_number}"

    row = OpenStruct.new(row_data)
    published_at = parse_datetime(row.published_at)

    lecture = Lecture.find_or_create_by!(
      title: row.title
    ) do |l|
      l.description  = row.description
      l.category     = row.category
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

  def parse_datetime(value)
    return nil unless value.present?
    return value if value.is_a?(DateTime) || value.is_a?(Time)
    DateTime.parse(value.to_s) rescue nil
  end

  def attach_from_url(record, attachment_name, url, content_type: nil)
    return if url.blank?

    Rails.logger.info "Enqueuing media download for #{attachment_name} from #{url} for record ##{record.id}"
    MediaDownloadJob.perform_later(
      record,
      attachment_name,
      url,
      content_type
    )
  rescue => e
    Rails.logger.error "Failed to enqueue media download for #{attachment_name}: #{e.message}"
  end
end
