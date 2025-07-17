# frozen_string_literal: true

class ImportRowJob < ApplicationJob
  queue_as :imports

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(importer_class, row_data, line_number, domain_id)
    Rails.logger.info "Processing row #{line_number} for #{importer_class}"

    importer = importer_class.constantize.new(nil, domain_id: domain_id)
    row = OpenStruct.new(row_data)

    importer.process_row(row, line_number)

    Rails.logger.info "Successfully processed row #{line_number} for #{importer_class}"
  rescue => e
    Rails.logger.error "Failed to process row #{line_number} for #{importer_class}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end
