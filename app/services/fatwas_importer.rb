class FatwasImporter < BaseImporter
  def initialize(file_path, sheet_name: "Fatwas", domain_id:)
    super(file_path, sheet_name:, domain_id:)
  end

  private

  def process_row(row, line)
    published_at = parse_datetime(row["published_at"])

    fatwa = Fatwa.find_or_create_by!(
      title:    row["title"],
      category: row["category"]
    ) do |f|
      f.question     = row["question"]
      f.answer       = row["answer"]
      f.published    = published_at.present?
      f.published_at = published_at
    end

    fatwa.assign_to(Domain.find(domain_id))
  end
end
