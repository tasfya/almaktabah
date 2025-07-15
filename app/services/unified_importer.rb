class UnifiedImporter
  attr_reader :file_path, :results

  def initialize(file_path)
    @file_path = file_path
    @results = {}
  end

  def import_all
    import_books
    import_lectures
    import_lessons
    import_benefits
    import_fatwas

    @results
  end

  def import_books(sheet_name = "Books")
    importer = BooksImporter.new(@file_path, sheet_name)
    importer.import
    @results[:books] = importer.import_summary
  end

  def import_lectures(sheet_name = "Lectures")
    importer = LecturesImporter.new(@file_path, sheet_name)
    importer.import
    @results[:lectures] = importer.import_summary
  end

  def import_lessons(sheet_name = "Lessons")
    importer = LessonsImporter.new(@file_path, sheet_name)
    importer.import
    @results[:lessons] = importer.import_summary
  end

  def import_benefits(sheet_name = "Benefits")
    importer = BenefitsImporter.new(@file_path, sheet_name)
    importer.import
    @results[:benefits] = importer.import_summary
  end

  def import_fatwas(sheet_name = "Fatwas")
    importer = FatwasImporter.new(@file_path, sheet_name)
    importer.import
    @results[:fatwas] = importer.import_summary
  end

  def print_summary
    puts "=" * 60
    puts "UNIFIED IMPORT SUMMARY"
    puts "=" * 60

    total_success = 0
    total_errors = 0

    @results.each do |content_type, summary|
      puts "\n#{content_type.to_s.upcase}:"
      puts "  ✅ Success: #{summary[:success_count]}"
      puts "  ❌ Errors:  #{summary[:error_count]}"

      if summary[:errors].any?
        puts "  Error details:"
        summary[:errors].each { |error| puts "    - #{error}" }
      end

      total_success += summary[:success_count]
      total_errors += summary[:error_count]
    end

    puts "\n" + "=" * 60
    puts "TOTAL: #{total_success} successful, #{total_errors} errors"
    puts "=" * 60
  end
end
