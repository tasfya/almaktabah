# frozen_string_literal: true

require "csv"

class CsvImportProcessor
  attr_reader :file_path, :job_class, :domain_id, :enqueued_count, :skipped_count, :errors

  def initialize(file_path, job_class, domain_id)
    @file_path = file_path
    @job_class = job_class
    @domain_id = domain_id
    @enqueued_count = 0
    @skipped_count = 0
    @errors = []
  end

  def process
    return false unless valid_file?

    Rails.logger.info "Starting CSV processing for #{job_class} from #{file_path}"

    line_number = 0
    CSV.foreach(file_path, headers: true, encoding: "utf-8") do |row|
      line_number += 1

      if row.to_h.values.all?(&:blank?)
        @skipped_count += 1
        next
      end

      begin
        # Enqueue the job for this row
        job_class.constantize.perform_later(
          row.to_h,
          domain_id,
          line_number + 1 # +1 for header line
        )

        @enqueued_count += 1

      rescue => e
        error_msg = "Failed to enqueue job for line #{line_number + 1}: #{e.message}"
        @errors << { line: line_number + 1, message: error_msg }
        Rails.logger.error error_msg
      end
    end

    Rails.logger.info "CSV processing completed: #{@enqueued_count} jobs enqueued, #{@skipped_count} rows skipped"
  end

  def summary
    {
      enqueued_count: @enqueued_count,
      skipped_count: @skipped_count,
      error_count: @errors.length,
      errors: @errors
    }
  end

  private

  def valid_file?
    unless File.exist?(file_path)
      @errors << { line: nil, message: "File not found: #{file_path}" }
      return false
    end

    unless File.extname(file_path).downcase == ".csv"
      @errors << { line: nil, message: "Only CSV files (.csv) are supported" }
      return false
    end

    true
  end
end
