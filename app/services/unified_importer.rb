class UnifiedImporter
  attr_reader :file_path, :domain_id, :results

  def initialize(file_path, domain_id:)
    @file_path = file_path
    @domain_id = domain_id
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

  def import_books
    importer = BooksImporter.new(@file_path, domain_id: @domain_id)
    importer.import
    @results[:books] = importer.summary
  end

  def import_lectures
    importer = LecturesImporter.new(@file_path, domain_id: @domain_id)
    importer.import
    @results[:lectures] = importer.summary
  end

  def import_lessons
    importer = LessonsImporter.new(@file_path, domain_id: @domain_id)
    importer.import
    @results[:lessons] = importer.summary
  end

  def import_benefits
    importer = BenefitsImporter.new(@file_path, domain_id: @domain_id)
    importer.import
    @results[:benefits] = importer.summary
  end

  def import_fatwas
    importer = FatwasImporter.new(@file_path, domain_id: @domain_id)
    importer.import
    @results[:fatwas] = importer.summary
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
