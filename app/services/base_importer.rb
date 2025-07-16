# frozen_string_literal: true

require "roo"
require "open-uri"
require "ostruct"

class BaseImporter
  attr_reader :file_path, :sheet_name, :domain_id, :errors, :success_count, :error_count

  def initialize(file_path, sheet_name: nil, domain_id:)
    raise ArgumentError, "domain_id is required" if domain_id.blank?

    @file_path   = file_path
    @sheet_name  = sheet_name
    @domain_id   = domain_id
    @errors      = []           # [{line: 123, message: "..."}, ...]
    @success_count = 0
    @error_count   = 0
  end

  def import
    return false unless valid_file?
    process_excel
    errors.empty?
  end

  def summary
    { success_count:, error_count:, errors: }
  end

  private

  def valid_file?
    unless File.exist?(file_path)
      add_error(line: nil, message: "File not found: #{file_path}")
      return false
    end
    unless excel_file?
      add_error(line: nil, message: "Only Excel files (.xlsx, .xls) are supported")
      return false
    end
    true
  end

  def excel_file? = %w[.xlsx .xls].include?(File.extname(file_path).downcase)

  def process_excel
    spreadsheet = open_spreadsheet

    if sheet_name
      unless spreadsheet.sheets.include?(sheet_name)
        add_error(line: nil, message: "Sheet '#{sheet_name}' not found. Available: #{spreadsheet.sheets.join(', ')}")
        return
      end
      spreadsheet.default_sheet = sheet_name
    end

    headers = spreadsheet.row(1).compact
    (2..spreadsheet.last_row).each do |line|
      row_hash = headers.zip(spreadsheet.row(line)).to_h.compact
      process_row(OpenStruct.new(row_hash), line)
      @success_count += 1
    rescue => e
      add_error(line:, message: e.message)
    end
  rescue => e
    add_error(line: nil, message: "Failed to process file: #{e.message}")
  end

  def open_spreadsheet
    case File.extname(file_path).downcase
    when ".xlsx" then Roo::Excelx.new(file_path)
    when ".xls"  then Roo::Excel.new(file_path)
    end
  end

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
