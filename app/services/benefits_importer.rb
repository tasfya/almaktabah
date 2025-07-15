class BenefitsImporter < BaseImporter
  def initialize(file_path, sheet_name = "Benefits")
    super(file_path, sheet_name)
  end

  private

  def process_row(row)
    begin
      published_at = parse_datetime(row["published_at"])
      benefit = Benefit.new(
        title: row["title"],
        description: row["description"],
        category: row["category"],
        published: published_at.present?,
        published_at: published_at
      )

      if benefit.save
        download_and_attach_file(benefit, :thumbnail, row["thumbnail_url"]) if row["thumbnail_url"].present?
        download_and_attach_file(benefit, :audio, row["audio_file_url"]) if row["audio_file_url"].present?
        download_and_attach_file(benefit, :video, row["video_file_url"]) if row["video_file_url"].present?

        log_success
      else
        log_error("Failed to create benefit: #{benefit.errors.full_messages.join(', ')}")
      end

    rescue => e
      log_error("Unexpected error: #{e.message}")
    end
  end
end
