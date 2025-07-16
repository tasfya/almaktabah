# frozen_string_literal: true

class LecturesImporter < BaseImporter
  def initialize(file_path, sheet_name: "Lectures", domain_id:)
    super(file_path, sheet_name:, domain_id:)
  end

  private

  def process_row(row, line)
    published_at = parse_datetime(row["published_at"])

    lecture = Lecture.find_or_create_by!(
      title: row["title"]
    ) do |l|
      l.description  = row["description"]
      l.category     = row["category"]
      l.video_url    = row["video_url"]
      l.youtube_url  = row["youtube_url"]
      l.published    = published_at.present?
      l.published_at = published_at
    end

    lecture.assign_to(Domain.find(domain_id))

    attach_from_url(lecture, :thumbnail, row["thumbnail_url"], content_type: "image/jpeg") if row["thumbnail_url"].present?
    attach_from_url(lecture, :audio,     row["audio_file_url"], content_type: "audio/mpeg") if row["audio_file_url"].present?
    attach_from_url(lecture, :video,     row["video_file_url"], content_type: "video/mp4") if row["video_file_url"].present?
  end
end
