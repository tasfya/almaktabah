namespace :import_resources do
  desc "Import books from Excel file"
  task :books, [ :file_path, :sheet_name, :domain_id ] => :environment do |t, args|
    file_path = args[:file_path]
    sheet_name = args[:sheet_name] || "Books"
    domain_id = args[:domain_id]

    if file_path.nil? || file_path.empty? || domain_id.nil? || domain_id.empty?
      puts "Usage: rails import_resources:books[/path/to/file.xlsx,SheetName,domain_id]"
      exit 1
    end
    puts "Importing books from: #{file_path}"
    puts "Using sheet: #{sheet_name}"
    puts "Domain ID: #{domain_id}"

    importer = BooksImporter.new(file_path, sheet_name: sheet_name, domain_id: domain_id.to_i)
    importer.import

    summary = importer.summary
    puts "Import completed!"
    puts "Successfully imported: #{summary[:success_count]} books"
    puts "Errors: #{summary[:error_count]}"

    if summary[:errors].any?
      puts "\nError details:"
      summary[:errors].each { |error| puts "- #{error}" }
    end
  end

  desc "Import lectures from Excel file"
  task :lectures, [ :file_path, :sheet_name, :domain_id ] => :environment do |t, args|
    file_path = args[:file_path]
    sheet_name = args[:sheet_name] || "Lectures"
    domain_id = args[:domain_id]

    if file_path.nil? || file_path.empty? || domain_id.nil? || domain_id.empty?
      puts "Usage: rails import_resources:lectures[/path/to/file.xlsx,SheetName,domain_id]"
      exit 1
    end

    puts "Importing lectures from: #{file_path}"
    puts "Using sheet: #{sheet_name}"
    puts "Domain ID: #{domain_id}"

    importer = LecturesImporter.new(file_path, sheet_name: sheet_name, domain_id: domain_id.to_i)
    importer.import

    summary = importer.summary
    puts "Import completed!"
    puts "Successfully imported: #{summary[:success_count]} lectures"
    puts "Errors: #{summary[:error_count]}"

    if summary[:errors].any?
      puts "\nError details:"
      summary[:errors].each { |error| puts "- #{error}" }
    end
  end

  desc "Import lessons from Excel file"
  task :lessons, [ :file_path, :sheet_name, :domain_id ] => :environment do |t, args|
    file_path = args[:file_path]
    sheet_name = args[:sheet_name] || "Lessons"
    domain_id = args[:domain_id]

    if file_path.nil? || file_path.empty? || domain_id.nil? || domain_id.empty?
      puts "Usage: rails import_resources:lessons[/path/to/file.xlsx,SheetName,domain_id]"
      exit 1
    end

    puts "Importing lessons from: #{file_path}"
    puts "Using sheet: #{sheet_name}"
    puts "Domain ID: #{domain_id}"

    importer = LessonsImporter.new(file_path, sheet_name, domain_id: domain_id.to_i)
    importer.import

    summary = importer.summary
    puts "Import completed!"
    puts "Successfully imported: #{summary[:success_count]} lessons"
    puts "Errors: #{summary[:error_count]}"

    if summary[:errors].any?
      puts "\nError details:"
      summary[:errors].each { |error| puts "- #{error}" }
    end
  end

  desc "Import benefits from Excel file"
  task :benefits, [ :file_path, :sheet_name, :domain_id ] => :environment do |t, args|
    file_path = args[:file_path]
    sheet_name = args[:sheet_name] || "Benefits"
    domain_id = args[:domain_id]

    if file_path.nil? || file_path.empty? || domain_id.nil? || domain_id.empty?
      puts "Usage: rails import_resources:benefits[/path/to/file.xlsx,SheetName,domain_id]"
      exit 1
    end

    puts "Importing benefits from: #{file_path}"
    puts "Using sheet: #{sheet_name}"
    puts "Domain ID: #{domain_id}"

    importer = BenefitsImporter.new(file_path, sheet_name: sheet_name, domain_id: domain_id.to_i)
    importer.import

    summary = importer.summary
    puts "Import completed!"
    puts "Successfully imported: #{summary[:success_count]} benefits"
    puts "Errors: #{summary[:error_count]}"

    if summary[:errors].any?
      puts "\nError details:"
      summary[:errors].each { |error| puts "- #{error}" }
    end
  end

  desc "Import fatwas from Excel file"
  task :fatwas, [ :file_path, :sheet_name, :domain_id ] => :environment do |t, args|
    file_path = args[:file_path]
    sheet_name = args[:sheet_name] || "Fatwas"
    domain_id = args[:domain_id]

    if file_path.nil? || file_path.empty? || domain_id.nil? || domain_id.empty?
      puts "Usage: rails import_resources:fatwas[/path/to/file.xlsx,SheetName,domain_id]"
      exit 1
    end

    puts "Importing fatwas from: #{file_path}"
    puts "Using sheet: #{sheet_name}"
    puts "Domain ID: #{domain_id}"

    importer = FatwasImporter.new(file_path, sheet_name: sheet_name, domain_id: domain_id.to_i)
    importer.import

    summary = importer.summary
    puts "Import completed!"
    puts "Successfully imported: #{summary[:success_count]} fatwas"
    puts "Errors: #{summary[:error_count]}"

    if summary[:errors].any?
      puts "\nError details:"
      summary[:errors].each { |error| puts "- #{error}" }
    end
  end

  desc "Import all content types from unified Excel file"
  task :all, [ :file_path, :domain_id ] => :environment do |t, args|
    file_path = args[:file_path]
    domain_id = args[:domain_id]

    if file_path.nil? || file_path.empty? || domain_id.nil? || domain_id.empty?
      puts "Usage: rails import_resources:all[/path/to/file.xlsx,domain_id]"
      exit 1
    end

    puts "Starting unified import from: #{file_path}"
    puts "Domain ID: #{domain_id}"
    puts "=" * 50

    importer = UnifiedImporter.new(file_path, domain_id: domain_id.to_i)
    importer.import_all
    importer.print_summary
  end

  desc "Display import template information"
  task info: :environment do
    puts "Excel Import System Information:"
    puts "=" * 50

    puts "Unified Template: data/excel_templates/almaktabah_import_template.xlsx"
    puts "\nAvailable Sheets:"
    puts "  • Books    - Islamic books and publications"
    puts "  • Lectures - Audio/video lectures and talks"
    puts "  • Lessons  - Educational lessons (can be part of series)"
    puts "  • Benefits - Short beneficial reminders"
    puts "  • Fatwas   - Religious rulings and Q&A"

    puts "\nUsage Examples:"
    puts "rails import_resources:generate_template                           # Generate unified template"
    puts "rails import_resources:all                                         # Import all from template"
    puts "rails import_resources:all[/path/to/your/file.xlsx]               # Import all from custom file"
    puts "rails import_resources:books                                       # Import books from default template"
    puts "rails import_resources:books[/path/to/file.xlsx]                  # Import books from custom file"
    puts "rails import_resources:books[/path/to/file.xlsx,CustomSheetName]  # Import from custom sheet"
    puts "rails import_resources:info                                       # Show this information"

    puts "\nFeatures:"
    puts "  ✅ Single Excel file with multiple tabs"
    puts "  ✅ Automatic file downloads from URLs"
    puts "  ✅ Smart published status calculation"
    puts "  ✅ Custom sheet name support"
    puts "  ✅ Unified or individual imports"
  end
end
