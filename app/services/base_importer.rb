class BaseImporter
  require "roo"
  require "net/http"
  require "uri"
  require "tempfile"
  require "ostruct"

  attr_reader :file_path, :sheet_name, :errors, :success_count, :error_count

  def initialize(file_path, sheet_name = nil)
    @file_path = file_path
    @sheet_name = sheet_name
    @errors = []
    @success_count = 0
    @error_count = 0
  end

  def import
    return false unless valid_file?

    process_excel
    @errors.empty?
  end

  def import_summary
    {
      success_count: @success_count,
      error_count: @error_count,
      errors: @errors
    }
  end

  private

  def valid_file?
    unless File.exist?(file_path)
      add_error("File not found: #{file_path}")
      return false
    end

    unless excel_file?
      add_error("Only Excel files (.xlsx, .xls) are supported")
      return false
    end

    true
  end

  def excel_file?
    %w[.xlsx .xls].include?(File.extname(file_path).downcase)
  end

  def process_excel
    spreadsheet = open_spreadsheet

    # Use specified sheet or default to first sheet
    if @sheet_name
      unless spreadsheet.sheets.include?(@sheet_name)
        add_error("Sheet '#{@sheet_name}' not found. Available sheets: #{spreadsheet.sheets.join(', ')}")
        return
      end
      spreadsheet.default_sheet = @sheet_name
    end

    headers = spreadsheet.row(1).compact

    (2..spreadsheet.last_row).each do |i|
      row_data = Hash[headers.zip(spreadsheet.row(i)[0, headers.size])]
      process_row(OpenStruct.new(row_data))
    end
  rescue => e
    add_error("Failed to process file: #{e.message}")
  end

  def open_spreadsheet
    case File.extname(file_path).downcase
    when ".xlsx" then Roo::Excelx.new(file_path)
    when ".xls" then Roo::Excel.new(file_path)
    end
  end

  def process_row(row)
    raise NotImplementedError, "Subclasses must implement process_row method"
  end

  def log_success
    @success_count += 1
  end

  # Helper methods
  def parse_boolean(value)
    return false if value.blank?
    %w[true 1 yes y].include?(value.to_s.downcase)
  end

  def parse_date(value)
    return nil if value.blank?
    Date.parse(value.to_s) rescue nil
  end

  def parse_datetime(value)
    return nil if value.blank?
    DateTime.parse(value.to_s) rescue nil
  end

  def log_error(message, row_number = nil)
    error_msg = row_number ? "Row #{row_number}: #{message}" : message
    @errors << error_msg
    @error_count += 1
  end

  def parse_integer(value)
    return nil if value.blank?
    value.to_i
  end

  def download_and_attach_file(record, attachment_name, url)
    return if url.blank?

    attachment_name = attachment_name.to_s if attachment_name.is_a?(Symbol)
    puts "Downloading #{attachment_name} from #{url} for record #{record.id}"

    begin
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == "https"

      request = Net::HTTP::Get.new(uri.request_uri)
      request["User-Agent"] = "Mozilla/5.0 (compatible; Ruby importer)"

      response = http.request(request)

      if response.code == "200"
        temp_file = Tempfile.new([ attachment_name, file_extension_from_url(url) ])
        temp_file.binmode
        temp_file.write(response.body)
        temp_file.rewind

        record.send(attachment_name).attach(
          io: temp_file,
          filename: filename_from_url(url) || "#{attachment_name}#{file_extension_from_url(url)}",
          content_type: content_type_from_url(url)
        )

        temp_file.close
        temp_file.unlink
      else
        log_error("Failed to download #{attachment_name} from #{url}: HTTP #{response.code}")
      end
    rescue => e
      log_error("Error downloading #{attachment_name} from #{url}: #{e.message}")
    end
  end

  def file_extension_from_url(url)
    return "" if url.blank?

    uri = URI.parse(url)
    extension = File.extname(uri.path)

    if extension.empty?
      case url.downcase
      when /\.jpe?g/i then ".jpg"
      when /\.png/i then ".png"
      when /\.pdf/i then ".pdf"
      when /\.mp3/i then ".mp3"
      when /\.mp4/i then ".mp4"
      when /\.wav/i then ".wav"
      when /\.webm/i then ".webm"
      end
    end

    extension
  rescue
    ""
  end

  def filename_from_url(url)
    return nil if url.blank?

    uri = URI.parse(url)
    filename = File.basename(uri.path)

    if filename.empty? || filename == "."
      timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
      extension = file_extension_from_url(url)
      filename = "file_#{timestamp}#{extension}"
    end

    filename
  rescue
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    extension = file_extension_from_url(url)
    "file_#{timestamp}#{extension}"
  end

  def content_type_from_url(url)
    extension = file_extension_from_url(url).downcase
    case extension
    when ".pdf" then "application/pdf"
    when ".mp3" then "audio/mpeg"
    when ".mp4" then "video/mp4"
    when ".jpg", ".jpeg" then "image/jpeg"
    when ".png" then "image/png"
    when ".webm" then "video/webm"
    when ".wav" then "audio/wav"
    when ".gif" then "image/gif"
    when ".webp" then "image/webp"
    else "application/octet-stream"
    end
  end

  def add_error(error)
    @error_count += 1
    @errors << error
  end
end
