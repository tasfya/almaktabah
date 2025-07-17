# frozen_string_literal: true

class FatwasImportJob < ApplicationJob
  queue_as :imports

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(row_data, domain_id, line_number = nil)
    Rails.logger.info "Processing fatwa import for line #{line_number}"

    row = OpenStruct.new(row_data)
    published_at = parse_datetime(row.published_at)

    fatwa = Fatwa.find_or_create_by!(
      title:    row.title,
      category: row.category
    ) do |f|
      f.question     = row.question
      f.answer       = row.answer
      f.published    = published_at.present?
      f.published_at = published_at
    end

    fatwa.assign_to(Domain.find(domain_id))

    Rails.logger.info "Successfully created/updated fatwa: #{fatwa.title}"
    fatwa
  rescue => e
    Rails.logger.error "Failed to process fatwa import for line #{line_number}: #{e.message}"
    raise e
  end

  private

  def parse_datetime(value)
    return nil unless value.present?
    return value if value.is_a?(DateTime) || value.is_a?(Time)
    DateTime.parse(value.to_s) rescue nil
  end
end
