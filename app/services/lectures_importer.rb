class LecturesImporter < BaseImporter
  def initialize(file_path, sheet_name = "Lectures")
    super(file_path, sheet_name)
  end

  private

  def process_row(row)
    begin
      published_at = parse_datetime(row["published_at"])
      lecture = Lecture.new(
        title: row["title"],
        description: row["description"],
        category: row["category"],
        video_url: row["video_url"],
        youtube_url: row["youtube_url"],
        published: published_at.present?,
        published_at: published_at
      )

      if lecture.save
        download_and_attach_file(lecture, :thumbnail, row["thumbnail_url"]) if row["thumbnail_url"].present?
        download_and_attach_file(lecture, :audio, row["audio_file_url"]) if row["audio_file_url"].present?
        download_and_attach_file(lecture, :video, row["video_file_url"]) if row["video_file_url"].present?

        log_success
      else
        log_error("Failed to create lecture: #{lecture.errors.full_messages.join(', ')}")
      end

    rescue => e
      log_error("Unexpected error: #{e.message}")
    end
  end
end
