# frozen_string_literal: true

require "csv"
require "open-uri"
require "ostruct"

class BaseImporter
  attr_reader :file_path, :domain_id, :errors, :success_count, :error_count

  def initialize(file_path, domain_id:)
    raise ArgumentError, "domain_id is required" if domain_id.blank?

    @file_path   = file_path
    @domain_id   = domain_id
    @errors      = []           # [{line: 123, message: "..."}, ...]
    @success_count = 0
    @error_count   = 0
  end

  def import
    return false unless valid_file?

    Rails.logger.info "Starting async import for #{self.class.name} from #{file_path}"

    total_rows = 0
    line_number = 0

    CSV.foreach(file_path, headers: true, encoding: "utf-8") do |row|
      line_number += 1
      next if row.to_h.values.all?(&:blank?) # Skip empty rows

      total_rows += 1

      # Queue individual row job
      ImportRowJob.perform_later(
        self.class.name,
        row.to_h,
        line_number + 1, # +1 for header line
        domain_id
      )
    end

    Rails.logger.info "Queued #{total_rows} row jobs for import"
    true
  rescue => e
    add_error(line: nil, message: "Failed to process import: #{e.message}")
    false
  end

  def summary
    { message: "Import jobs have been queued. Check logs for progress." }
  end

  private

  def valid_file?
    unless File.exist?(file_path)
      add_error(line: nil, message: "File not found: #{file_path}")
      return false
    end
    unless csv_file?
      add_error(line: nil, message: "Only CSV files (.csv) are supported")
      return false
    end
    true
  end

  def csv_file? = File.extname(file_path).downcase == ".csv"

  def process_row(row, line)
    raise NotImplementedError, "#{self.class} must implement #process_row(row, line)"
  end

  def parse_boolean(value)
    # it support true/false, 1/0, yes/no, Y/N
    return true if value.to_s.match?(/\A(true|1|yes|y)\z/i)
    return false if value.to_s.match?(/\A(false|0|no|n)\z/i)
    nil
  end

  def parse_date(value)
    return nil unless value.present?
    Date.parse(value.to_s) rescue nil
  end

  def parse_datetime(value)
    return nil unless value.present?
    return value if value.is_a?(DateTime) || value.is_a?(Time)
    DateTime.parse(value.to_s) rescue nil
  end

  def parse_integer(value)
    Integer(value) rescue nil
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
    add_error(line: nil, message: "Failed to enqueue media download for #{attachment_name}: #{e.message}")
  end

  def add_error(line:, message:)
    errors << { line:, message: }
    @error_count += 1
  end
end
