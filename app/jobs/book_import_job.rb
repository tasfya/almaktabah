# frozen_string_literal: true

require "ostruct"

class BookImportJob < ApplicationJob
  include ApplicationHelper

  queue_as :default

  def perform(row_data, domain_id, line_number = nil)
    Rails.logger.info "Processing book import for line #{line_number}"

    row = ::OpenStruct.new(row_data)

    if row_data["scholar_id"]
      scholar = Scholar.find(row_data["scholar_id"])
    elsif row.scholar_full_name.present?
      scholar = find_or_create_scholar_by_full_name(row.scholar_full_name)
    else
      raise ArgumentError, "Author information (scholar_id or scholar_full_name) is required"
    end

    published_at = parse_datetime(row.published_at)

    book = Book.find_or_create_by!(
      title: row.title
    ) do |b|
      b.description  = row.description
      b.category     = row.category
      b.scholar       = scholar
      b.pages        = parse_integer(row.pages)
      b.published    = published_at.present?
      b.published_at = published_at
    end

    book.assign_to(Domain.find(domain_id))

    # Handle file attachments
    attach_from_url(book, :file, row.file_url) if row.file_url.present?
    attach_from_url(book, :cover_image, row.cover_image_url) if row.cover_image_url.present?

    Rails.logger.info "Successfully created/updated book: #{book.title}"
    book
  rescue => e
    Rails.logger.error "Failed to process book import for line #{line_number}: #{e.message}"
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
end
