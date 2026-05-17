# frozen_string_literal: true

require "csv"

class LectureCsvImportService
  attr_reader :csv_file, :scholar, :skip_duplicates, :created_count, :skipped_count, :errors

  def initialize(csv_file:, scholar:, skip_duplicates: true)
    @csv_file = csv_file
    @scholar = scholar
    @skip_duplicates = skip_duplicates
    @created_count = 0
    @skipped_count = 0
    @errors = []
  end

  def import
    unless valid_csv?
      return result
    end

    existing_titles = scholar.lectures.pluck(:title).map(&:downcase) if skip_duplicates

    csv_content = csv_file.read.force_encoding("UTF-8")
    csv_data = CSV.parse(csv_content, headers: true)

    unless csv_data.headers.include?("title")
      @errors << "CSV must have a 'title' column"
      return result
    end

    csv_data.each.with_index(2) do |row, line_number|
      process_row(row, line_number, existing_titles)
    end

    result
  end

  private

  def process_row(row, line_number, existing_titles)
    title = row["title"]&.strip

    if title.blank?
      @skipped_count += 1
      return
    end

    if skip_duplicates && existing_titles&.include?(title.downcase)
      @skipped_count += 1
      return
    end

    lecture = scholar.lectures.build(
      title: title,
      kind: parse_kind(row["kind"]),
      youtube_url: row["youtube_url"]&.strip.presence
    )

    if lecture.save
      @created_count += 1
      existing_titles&.push(title.downcase)
    else
      @errors << "Line #{line_number}: #{lecture.errors.full_messages.join(', ')}"
    end
  rescue => e
    @errors << "Line #{line_number}: #{e.message}"
  end

  def parse_kind(value)
    return nil if value.blank?

    kind = value.strip.downcase
    return kind if Lecture.kinds.key?(kind)

    # Try to parse as integer
    int_value = Integer(kind) rescue nil
    return int_value if int_value && Lecture.kinds.values.include?(int_value)

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
      errors: @errors
    }
  end
end
