class BooksImporter < BaseImporter
  def initialize(file_path, sheet_name = "Books")
    super(file_path, sheet_name)
  end

  private

  def process_row(row)
    begin
      author = find_or_create_author(row["author_first_name"], row["author_last_name"])
      unless author
        log_error("Could not create author for: #{row['author_first_name']} #{row['author_last_name']}")
        return
      end

      published_at = parse_datetime(row["published_at"])
      book = Book.new(
        title: row["title"],
        description: row["description"],
        category: row["category"],
        author: author,
        pages: parse_integer(row["pages"]),
        published: published_at.present?,
        published_at: published_at
      )

      if book.save
        download_and_attach_file(book, :file, row["file_url"]) if row["file_url"].present?
        download_and_attach_file(book, :cover_image, row["cover_image_url"]) if row["cover_image_url"].present?

        log_success
      else
        log_error("Failed to create book: #{book.errors.full_messages.join(', ')}")
      end

    rescue => e
      log_error("Unexpected error: #{e.message}")
    end
  end

  def find_or_create_author(first_name, last_name)
    return nil if first_name.blank? && last_name.blank?

    Scholar.find_or_create_by(
      first_name: first_name&.strip,
      last_name: last_name&.strip
    ) do |scholar|
      scholar.published = true
      scholar.published_at = Time.current
    end
  rescue
    nil
  end
end
