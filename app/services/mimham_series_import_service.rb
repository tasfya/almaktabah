# frozen_string_literal: true

require "csv"

class MimhamSeriesImportService
  attr_reader :csv_file, :skip_duplicates, :download_audio, :dry_run,
              :created_count, :skipped_count, :errors, :scholars_cache, :series_cache,
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
    @series_cache = {}
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

    required_headers = %w[series_title scholar_name title]
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
    puts "  New lessons:      #{new_records.count}"
    puts "  Existing lessons: #{existing_records.count}"
    puts "  Errors:           #{errors.count}"
    puts

    if existing_records.any?
      puts "-" * 60
      puts "EXISTING LESSONS (would be skipped):"
      puts "-" * 60
      existing_records.first(20).each do |record|
        puts "  [#{record[:series_title]}] #{record[:title]}"
        puts "    Source: #{record[:source_url]}"
      end
      puts "  ... and #{existing_records.count - 20} more" if existing_records.count > 20
      puts
    end

    if new_records.any?
      puts "-" * 60
      puts "NEW LESSONS (#{dry_run ? 'would be imported' : 'imported'}):"
      puts "-" * 60
      new_records.first(20).each do |record|
        puts "  [#{record[:series_title]}] #{record[:title]}"
        puts "    Scholar: #{record[:scholar_name]} | Position: #{record[:lesson_number]}"
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
    series_title = row["series_title"]&.strip
    scholar_name = row["scholar_name"]&.strip
    title = row["title"]&.strip

    if series_title.blank? || scholar_name.blank? || title.blank?
      @skipped_count += 1
      return
    end

    source_url = row["source_url"]&.strip.presence
    lesson_number = row["lesson_number"]&.strip&.to_i

    record_info = {
      series_title: series_title,
      scholar_name: scholar_name,
      lesson_number: lesson_number,
      title: title,
      source_url: source_url,
      audio_url: row["audio_url"]&.strip,
      published_at: row["published_at"]&.strip,
      duration: row["duration"]&.strip
    }

    # Check for duplicates by source_url
    existing = check_existing(source_url, series_title, scholar_name, title)

    if existing
      @existing_records << record_info.merge(existing_id: existing.id)
      @skipped_count += 1
      return
    end

    @new_records << record_info

    # If dry run, don't actually create
    return if dry_run

    series = find_or_create_series(series_title, scholar_name)
    unless series
      @errors << "Line #{line_number}: Could not find or create series '#{series_title}' for scholar '#{scholar_name}'"
      return
    end

    lesson = series.lessons.build(
      title: title,
      position: lesson_number,
      source_url: source_url,
      published_at: parse_date(row["published_at"]),
      duration: parse_duration(row["duration"])
    )

    if lesson.save
      @created_count += 1

      # Queue audio download job if enabled
      audio_url = row["audio_url"]&.strip.presence
      if download_audio && audio_url
        MimhamAudioDownloadJob.perform_later("Lesson", lesson.id, audio_url)
      end
    else
      @errors << "Line #{line_number}: #{lesson.errors.full_messages.join(', ')}"
    end
  rescue => e
    @errors << "Line #{line_number}: #{e.message}"
  end

  def check_existing(source_url, series_title, scholar_name, title)
    if source_url.present?
      Lesson.find_by(source_url: source_url)
    else
      # Try to find by series + title
      scholar = find_scholar(scholar_name)
      return nil unless scholar

      series = scholar.series.find_by(title: series_title)
      return nil unless series

      series.lessons.find_by(title: title)
    end
  end

  def find_scholar(name)
    return @scholars_cache[name] if @scholars_cache.key?(name)

    scholar = Scholar.find_by(name: name)
    scholar ||= Scholar.where("name LIKE ?", "%#{name}%").first

    @scholars_cache[name] = scholar
    scholar
  end

  def find_or_create_series(series_title, scholar_name)
    cache_key = "#{scholar_name}:#{series_title}"
    return @series_cache[cache_key] if @series_cache.key?(cache_key)

    scholar = find_scholar(scholar_name)
    unless scholar
      # Create new scholar if not found
      scholar = Scholar.create(name: scholar_name)
      unless scholar.persisted?
        return nil
      end
      @scholars_cache[scholar_name] = scholar
    end

    # Try to find existing series
    series = scholar.series.find_by(title: series_title)

    # Create new series if not found
    unless series
      series = scholar.series.create(title: series_title, published: false)
      unless series.persisted?
        return nil
      end
    end

    @series_cache[cache_key] = series
    series
  end

  def parse_date(value)
    return nil if value.blank?
    Date.parse(value)
  rescue Date::Error
    nil
  end

  def parse_duration(value)
    return nil if value.blank?

    # Handle HH:MM:SS or MM:SS format
    parts = value.split(":").map(&:to_i)
    case parts.size
    when 3
      parts[0] * 3600 + parts[1] * 60 + parts[2]
    when 2
      parts[0] * 60 + parts[1]
    else
      nil
    end
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
      series_created: dry_run ? 0 : @series_cache.values.count { |s| s.created_at > 1.minute.ago }
    }
  end
end
