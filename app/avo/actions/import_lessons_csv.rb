class Avo::Actions::ImportLessonsCsv < Avo::BaseAction
  self.name = "Import Lessons from CSV"
  self.standalone = true
  self.visible = -> { true }

  def fields
    field :csv_file, as: :file, help: "CSV file with columns: position, title, youtube_url"
    field :series_id, as: :select, name: "Series", options: -> {
      Series.includes(:scholar).order("scholars.full_name, series.title").map do |s|
        [ "#{s.scholar.name} - #{s.title}", s.id ]
      end
    }, help: "Select the series to add lessons to"
    field :skip_duplicates, as: :boolean, default: true, help: "Skip lessons with duplicate titles in the series"
  end

  def handle(**args)
    fields = args[:fields]

    csv_file = fields[:csv_file]
    series_id = fields[:series_id]
    skip_duplicates = fields[:skip_duplicates]

    if csv_file.blank?
      return error "Please upload a CSV file"
    end

    if series_id.blank?
      return error "Please select a series"
    end

    series = Series.find_by(id: series_id)
    unless series
      return error "Series not found"
    end

    service = LessonCsvImportService.new(
      csv_file: csv_file,
      series: series,
      skip_duplicates: skip_duplicates
    )

    result = service.import

    if result[:errors].any?
      error "Import completed with errors: #{result[:errors].first(3).join(', ')}"
    else
      succeed "Successfully created #{result[:created_count]} lessons. Skipped #{result[:skipped_count]} rows."
    end
  end
end
