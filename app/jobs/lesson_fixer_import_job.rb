# frozen_string_literal: true

require "ostruct"

class LessonFixerImportJob < ApplicationJob
  include ApplicationHelper
  queue_as :default

  def perform(row_data, domain_id, line_number = nil)
    Rails.logger.info "Processing lesson import for line #{line_number}"

    row = ::OpenStruct.new(row_data)

    if row_data["scholar_id"]
      scholar = Scholar.find(row_data["scholar_id"])
    elsif row_data["scholar_full_name"].present?
      scholar = find_or_create_scholar_by_full_name(row_data["scholar_full_name"])
    end

    series = find_or_create_series(row.series_title, scholar) if row.series_title.present?

    lesson = Lesson.find_by(source_url: row.source_url)
    unless lesson.series.id == series.id
      lesson.series = series
      lesson.save!
      Rails.logger.info "Successfully updated lesson: #{lesson.title}"
    end
    lesson
  rescue => e
    Rails.logger.error "Failed to process lesson import for line #{line_number}: #{e.message}"
    raise e
  end

  private

  def find_or_create_scholar_by_full_name(full_name)
    return nil if full_name.blank?

    Scholar.find_or_create_by!(full_name: full_name.strip) do |s|
      s.published = true
      s.published_at = Time.current
    end
  end

  def find_or_create_scholar(first_name, last_name)
    return nil if first_name.blank? && last_name.blank?

    Scholar.find_or_create_by!(
      first_name: first_name&.strip,
      last_name: last_name&.strip
    ) do |s|
      s.published = true
      s.published_at = Time.current
    end
  end

  def find_or_create_series(title, scholar)
    return nil if title.blank? || scholar.nil?
    Series.find_or_create_by!(title: title.strip, scholar: scholar)
  rescue
    nil
  end
end
