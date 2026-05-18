class Avo::Actions::ImportScholarLessonsCsv < Avo::BaseAction
  self.name = "Import Lessons from CSV"

  def fields
    field :csv_file, as: :file, help: "CSV file with columns: series, title, position, youtube_url"
  end

  def handle(**args)
    fields = args[:fields]
    records = args[:records]

    csv_file = fields[:csv_file]

    if csv_file.blank?
      return error "Please upload a CSV file"
    end

    total_created = 0
    total_skipped = 0
    total_series_created = 0
    all_errors = []

    records.each do |scholar|
      service = ScholarLessonCsvImportService.new(
        csv_file: csv_file,
        scholar: scholar
      )

      result = service.import
      total_created += result[:created_count]
      total_skipped += result[:skipped_count]
      total_series_created += result[:series_created_count]
      all_errors.concat(result[:errors])

      csv_file.rewind if csv_file.respond_to?(:rewind)
    end

    if all_errors.any?
      error "Import completed with errors: #{all_errors.first(3).join(', ')}"
    else
      succeed "Created #{total_created} lessons in #{total_series_created} new series. Skipped #{total_skipped} rows."
    end
  end
end
