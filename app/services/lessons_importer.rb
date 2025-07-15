class LessonsImporter < BaseImporter
  def initialize(file_path, sheet_name = "Lessons")
    super(file_path, sheet_name)
  end

  private

  def process_row(row)
    begin
      # Find series if specified
      series = find_series(row["series_title"]) if row["series_title"].present?

      published_at = parse_datetime(row["published_at"])
      lesson = Lesson.new(
        title: row["title"],
        description: row["description"],
        category: row["category"],
        content_type: row["content_type"] || "audio",
        series: series,
        video_url: row["video_url"],
        youtube_url: row["youtube_url"],
        position: parse_integer(row["position"]),
        published: published_at.present?,
        published_at: published_at
      )

      if lesson.save
        download_and_attach_file(lesson, :thumbnail, row["thumbnail_url"]) if row["thumbnail_url"].present?
        download_and_attach_file(lesson, :audio, row["audio_file_url"]) if row["audio_file_url"].present?
        download_and_attach_file(lesson, :video, row["video_file_url"]) if row["video_file_url"].present?

        log_success
      else
        log_error("Failed to create lesson: #{lesson.errors.full_messages.join(', ')}")
      end

    rescue => e
      log_error("Unexpected error: #{e.message}")
    end
  end

  def find_series(title)
    return nil if title.blank?

    Series.find_by(title: title.strip) ||
    Series.create!(
      title: title.strip,
      published: true,
      published_at: Time.current
    )
  rescue
    nil
  end
end
