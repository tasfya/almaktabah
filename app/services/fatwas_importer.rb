class FatwasImporter < BaseImporter
  def initialize(file_path, sheet_name = "Fatwas")
    super(file_path, sheet_name)
  end

  private

  def process_row(row)
    begin
      published_at = parse_datetime(row["published_at"])
      fatwa = Fatwa.new(
        title: row["title"],
        category: row["category"],
        published: published_at.present?,
        published_at: published_at
      )
      fatwa.question = row["question"] if row["question"].present?
      fatwa.answer = row["answer"] if row["answer"].present?

      if fatwa.save
        log_success
      else
        log_error("Failed to create fatwa: #{fatwa.errors.full_messages.join(', ')}")
      end

    rescue => e
      log_error("Unexpected error: #{e.message}")
    end
  end
end
