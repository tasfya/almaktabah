# frozen_string_literal: true

class BenefitsImporter < BaseImporter
  def initialize(file_path, sheet_name: "Benefits", domain_id:)
    super(file_path, sheet_name:, domain_id:)
  end

  private

  def process_row(row, line)
    published_at = parse_datetime(row["published_at"])

    benefit = Benefit.find_or_create_by!(
      title: row["title"]
    ) do |b|
      b.description  = row["description"]
      b.category     = row["category"]
      b.published    = published_at.present?
      b.published_at = published_at
    end

    benefit.assign_to(Domain.find(domain_id))

    attach_from_url(benefit, :thumbnail, row["thumbnail_url"], content_type: "image/jpeg") if row["thumbnail_url"].present?
    attach_from_url(benefit, :audio,     row["audio_file_url"], content_type: "audio/mpeg") if row["audio_file_url"].present?
    attach_from_url(benefit, :video,     row["video_file_url"], content_type: "video/mp4") if row["video_file_url"].present?
  end
end
