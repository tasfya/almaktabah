# frozen_string_literal: true

class BooksImporter < BaseImporter
  def initialize(file_path, sheet_name: "Books", domain_id:)
    super(file_path, sheet_name:, domain_id:)
  end

  private

  def process_row(row, line)
    author = find_or_create_author(row["author_first_name"], row["author_last_name"])
    raise "Could not create/find author" unless author

    published_at = parse_datetime(row["published_at"])

    book = Book.find_or_create_by!(
      title: row["title"]
    ) do |b|
      b.description  = row["description"]
      b.category     = row["category"]
      b.author       = author
      b.pages        = parse_integer(row["pages"])
      b.published    = published_at.present?
      b.published_at = published_at
    end

    book.assign_to(Domain.find(domain_id))

    attach_from_url(book, :file,        row["file_url"])       if row["file_url"].present?
    attach_from_url(book, :cover_image, row["cover_image_url"]) if row["cover_image_url"].present?
  end

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
