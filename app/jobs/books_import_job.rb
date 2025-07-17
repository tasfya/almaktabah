# frozen_string_literal: true

class BooksImportJob < ApplicationJob
  queue_as :default


  def perform(row_data, domain_id, line_number = nil)
    Rails.logger.info "Processing book import for line #{line_number}"

    row = OpenStruct.new(row_data)

    # Find or create author
    author = find_or_create_author(row.author_first_name, row.author_last_name)
    raise "Could not create/find author" unless author

    published_at = parse_datetime(row.published_at)

    book = Book.find_or_create_by!(
      title: row.title
    ) do |b|
      b.description  = row.description
      b.category     = row.category
      b.author       = author
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

  def find_or_create_author(first_name, last_name)
    return nil if first_name.blank? && last_name.blank?

    Scholar.find_or_create_by!(
      first_name: first_name&.strip,
      last_name:  last_name&.strip
    ) do |s|
      s.published    = true
      s.published_at = Time.current
    end
  end
end
