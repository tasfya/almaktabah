# frozen_string_literal: true

class BenefitImportJob < ApplicationJob
  include ApplicationHelper

  queue_as :default

  def perform(row_data, domain_id, line_number = nil)
    Rails.logger.info "Processing benefit import for line #{line_number}"

    row = OpenStruct.new(row_data)
    published_at = parse_datetime(row.published_at)

    benefit = Benefit.find_or_create_by!(
      title: row.title
    ) do |b|
      b.description  = row.description
      b.category     = row.category
      b.published    = published_at.present?
      b.published_at = published_at
    end

    benefit.assign_to(Domain.find(domain_id))

    # Handle file attachments
    attach_from_url(benefit, :thumbnail, row.thumbnail_url) if row.thumbnail_url.present?
    attach_from_url(benefit, :audio, row.audio_file_url) if row.audio_file_url.present?
    attach_from_url(benefit, :video, row.video_file_url) if row.video_file_url.present?

    Rails.logger.info "Successfully created/updated benefit: #{benefit.title}"
    benefit
  rescue => e
    Rails.logger.error "Failed to process benefit import for line #{line_number}: #{e.message}"
    raise e
  end
end
