# frozen_string_literal: true

require "csv"

class ScholarLessonCsvImportService
  attr_reader :csv_file, :scholar, :created_count, :skipped_count, :series_created_count, :errors

  def initialize(csv_file:, scholar:)
    @csv_file = csv_file
    @scholar = scholar
    @created_count = 0
    @skipped_count = 0
    @series_created_count = 0
    @errors = []
    @series_cache = {}
  end

  def import
    unless valid_csv?
      return result
    end

    csv_content = csv_file.read.force_encoding("UTF-8")
    csv_data = CSV.parse(csv_content, headers: true)

    unless csv_data.headers.include?("title") && csv_data.headers.include?("series")
      @errors << "CSV must have 'title' and 'series' columns"
      return result
    end

    csv_data.each.with_index(2) do |row, line_number|
      process_row(row, line_number)
    end

    result
  end

  private

  def process_row(row, line_number)
    title = row["title"]&.strip
    series_title = row["series"]&.strip
    youtube_url = row["youtube_url"]&.strip.presence

    if title.blank? || series_title.blank?
      @skipped_count += 1
      return
    end

    # Skip if youtube_url already exists
    if youtube_url.present? && Lesson.exists?(youtube_url: youtube_url)
      @skipped_count += 1
      return
    end

    series = find_or_create_series(series_title)

    lesson = series.lessons.build(
      title: title,
      position: parse_position(row["position"]),
      youtube_url: youtube_url
    )

    if lesson.save
      @created_count += 1
    else
      @errors << "Line #{line_number}: #{lesson.errors.full_messages.join(', ')}"
    end
  rescue => e
    @errors << "Line #{line_number}: #{e.message}"
  end

  def find_or_create_series(title)
    return @series_cache[title] if @series_cache[title]

    series = scholar.series.find_by(title: title)

    if series.nil?
      series = scholar.series.create!(title: title)
      @series_created_count += 1
    end

    @series_cache[title] = series
    series
  end

  def parse_position(value)
    return nil if value.blank?
    Integer(value.strip)
  rescue ArgumentError
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
      created_count: @created_count,
      skipped_count: @skipped_count,
      series_created_count: @series_created_count,
      errors: @errors
    }
  end
end
