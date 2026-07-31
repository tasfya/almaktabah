# frozen_string_literal: true

require "csv"
require "down"

class MimhamImportService
  attr_reader :csv_file, :skip_duplicates, :download_audio, :dry_run,
              :created_count, :skipped_count, :errors, :scholars_cache,
              :existing_records, :new_records

  def initialize(csv_file:, skip_duplicates: true, download_audio: true, dry_run: false)
    @csv_file = csv_file
    @skip_duplicates = skip_duplicates
    @download_audio = download_audio
    @dry_run = dry_run
    @created_count = 0
    @skipped_count = 0
    @errors = []
    @scholars_cache = {}
    @existing_records = []
    @new_records = []
  end

  def import
    unless valid_csv?
      return result
    end

    csv_content = csv_file.is_a?(String) ? File.read(csv_file) : csv_file.read
    csv_content = csv_content.force_encoding("UTF-8")
    csv_data = CSV.parse(csv_content, headers: true)

    required_headers = %w[title scholar_name kind]
    missing = required_headers - csv_data.headers
    if missing.any?
      @errors << "CSV missing required columns: #{missing.join(', ')}"
      return result
    end

    csv_data.each.with_index(2) do |row, line_number|
      process_row(row, line_number)
    end

    result
  end

  def print_report
    puts "=" * 60
    puts dry_run ? "DRY RUN REPORT" : "IMPORT REPORT"
    puts "=" * 60
    puts
    puts "Summary:"
    puts "  New records:      #{new_records.count}"
    puts "  Existing records: #{existing_records.count}"
    puts "  Errors:           #{errors.count}"
    puts

    if existing_records.any?
      puts "-" * 60
      puts "EXISTING RECORDS (would be skipped):"
      puts "-" * 60
      existing_records.first(20).each do |record|
        puts "  [#{record[:scholar_name]}] #{record[:title]}"
        puts "    Source: #{record[:source_url]}"
      end
      puts "  ... and #{existing_records.count - 20} more" if existing_records.count > 20
      puts
    end

    if new_records.any?
      puts "-" * 60
      puts "NEW RECORDS (#{dry_run ? 'would be imported' : 'imported'}):"
      puts "-" * 60
      new_records.first(20).each do |record|
        puts "  [#{record[:scholar_name]}] #{record[:title]}"
        puts "    Kind: #{record[:kind]} | Category: #{record[:category]}"
      end
      puts "  ... and #{new_records.count - 20} more" if new_records.count > 20
      puts
    end

    if errors.any?
      puts "-" * 60
      puts "ERRORS:"
      puts "-" * 60
      errors.first(20).each { |e| puts "  #{e}" }
      puts "  ... and #{errors.count - 20} more" if errors.count > 20
    end

    puts "=" * 60
  end

  private

  def process_row(row, line_number)
    title = row["title"]&.strip
    scholar_name = row["scholar_name"]&.strip

    if title.blank? || scholar_name.blank?
      @skipped_count += 1
      return
    end

    record_info = {
      title: title,
      scholar_name: scholar_name,
      kind: row["kind"]&.strip,
      category: row["category"]&.strip,
      source_url: row["source_url"]&.strip,
      audio_url: row["audio_url"]&.strip,
      published_at: row["published_at"]&.strip
    }

    # Check for duplicates by source_url or title
    source_url = record_info[:source_url].presence
    existing = check_existing(scholar_name, title, source_url)

    if existing
      @existing_records << record_info.merge(existing_id: existing.id)
      @skipped_count += 1
      return
    end

    @new_records << record_info

    # If dry run, don't actually create
    return if dry_run

    scholar = find_or_create_scholar(scholar_name)
    unless scholar
      @errors << "Line #{line_number}: Could not find or create scholar '#{scholar_name}'"
      return
    end

    lecture = scholar.lectures.build(
      title: title,
      kind: parse_kind(row["kind"]),
      category: row["category"]&.strip.presence,
      source_url: source_url,
      published_at: parse_date(row["published_at"])
    )

    if lecture.save
      @created_count += 1

      # Download and attach audio if enabled
      audio_url = row["audio_url"]&.strip.presence
      if download_audio && audio_url
        attach_audio(lecture, audio_url, line_number)
      end
    else
      @errors << "Line #{line_number}: #{lecture.errors.full_messages.join(', ')}"
    end
  rescue => e
    @errors << "Line #{line_number}: #{e.message}"
  end

  def check_existing(scholar_name, title, source_url)
    if source_url.present?
      Lecture.find_by(source_url: source_url)
    else
      scholar = Scholar.find_by(name: scholar_name) ||
                Scholar.where("name LIKE ?", "%#{scholar_name}%").first
      scholar&.lectures&.find_by(title: title)
    end
  end

  def attach_audio(lecture, audio_url, line_number)
    tempfile = Down.download(audio_url, max_size: 500 * 1024 * 1024) # 500MB max
    filename = "#{lecture.title.parameterize}.mp3"

    lecture.audio.attach(
      io: tempfile,
      filename: filename,
      content_type: "audio/mpeg"
    )

    tempfile.close
    tempfile.unlink if tempfile.respond_to?(:unlink)
  rescue Down::Error => e
    @errors << "Line #{line_number}: Audio download failed - #{e.message}"
  rescue => e
    @errors << "Line #{line_number}: Audio attach failed - #{e.message}"
  end

  def find_or_create_scholar(name)
    return @scholars_cache[name] if @scholars_cache.key?(name)

    # Try exact match first
    scholar = Scholar.find_by(name: name)

    # Try partial match
    scholar ||= Scholar.where("name LIKE ?", "%#{name}%").first

    # Create new scholar if not found
    unless scholar
      scholar = Scholar.create(name: name)
      unless scholar.persisted?
        return nil
      end
    end

    @scholars_cache[name] = scholar
    scholar
  end

  def parse_kind(value)
    return nil if value.blank?

    kind = value.strip.downcase
    return kind if Lecture.kinds.key?(kind)

    int_value = Integer(kind) rescue nil
    return int_value if int_value && Lecture.kinds.values.include?(int_value)

    nil
  end

  def parse_date(value)
    return nil if value.blank?
    Date.parse(value)
  rescue Date::Error
    nil
  end

  def valid_csv?
    if csv_file.blank?
      @errors << "No CSV file provided"
      return false
    end

    true
  end

  def result
    {
      dry_run: dry_run,
      created_count: dry_run ? 0 : @created_count,
      would_create_count: @new_records.count,
      skipped_count: @skipped_count,
      existing_count: @existing_records.count,
      new_records: @new_records,
      existing_records: @existing_records,
      errors: @errors,
      scholars_created: dry_run ? 0 : @scholars_cache.values.count { |s| s.created_at > 1.minute.ago }
    }
  end
end
