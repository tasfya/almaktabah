class Avo::Actions::ImportLessonsCsv < Avo::BaseAction
  self.name = "Import Lessons from CSV"

  def fields
    field :csv_file, as: :file, help: "CSV file with columns: position, title, youtube_url"
    field :skip_duplicates, as: :boolean, default: true, help: "Skip lessons with duplicate titles in the series"
  end

  def handle(**args)
    fields = args[:fields]
    records = args[:records]

    csv_file = fields[:csv_file]
    skip_duplicates = fields[:skip_duplicates]

    if csv_file.blank?
      return error "Please upload a CSV file"
    end

    total_created = 0
    total_skipped = 0
    all_errors = []

    records.each do |series|
      service = LessonCsvImportService.new(
        csv_file: csv_file,
        series: series,
        skip_duplicates: skip_duplicates
      )

      result = service.import
      total_created += result[:created_count]
      total_skipped += result[:skipped_count]
      all_errors.concat(result[:errors])

      csv_file.rewind if csv_file.respond_to?(:rewind)
    end

    if all_errors.any?
      error "Import completed with errors: #{all_errors.first(3).join(', ')}"
    else
      succeed "Successfully created #{total_created} lessons. Skipped #{total_skipped} rows."
    end
  end
end
