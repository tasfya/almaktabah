# frozen_string_literal: true

class ImportBatchJob < ApplicationJob
  queue_as :imports

  def perform(importer_class, file_path, domain_id)
    Rails.logger.info "Starting import for #{importer_class} from #{file_path}"

    unless File.exist?(file_path)
      Rails.logger.error "File not found: #{file_path}"
      return
    end

    unless File.extname(file_path).downcase == ".csv"
      Rails.logger.error "Only CSV files are supported: #{file_path}"
      return
    end

    total_rows = 0
    line_number = 0

    CSV.foreach(file_path, headers: true, encoding: "utf-8") do |row|
      line_number += 1
      next if row.to_h.values.all?(&:blank?) # Skip empty rows

      total_rows += 1

      # Queue individual row job
      ImportRowJob.perform_later(
        importer_class,
        row.to_h,
        line_number + 1, # +1 for header line
        domain_id
      )
    end

    Rails.logger.info "Queued #{total_rows} row jobs for import"
  rescue => e
    Rails.logger.error "Failed to process import: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end
