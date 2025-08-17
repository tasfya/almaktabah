namespace :import_resources do
  desc "Import books from CSV file (async)"
  task :books, [ :file_path, :domain_id ] => :environment do |t, args|
    file_path = args[:file_path]
    domain_id = args[:domain_id]

    if file_path.nil? || file_path.empty? || domain_id.nil? || domain_id.empty?
      puts "Usage: rails import_resources:books[/path/to/file.csv,domain_id]"
      exit 1
    end

    puts "Processing CSV and enqueuing book import jobs from: #{file_path}"
    puts "Domain ID: #{domain_id}"

    processor = CsvImportProcessor.new(file_path, "BookImportJob", domain_id.to_i)
    processor.process

    summary = processor.summary
    puts "CSV processing completed!"
    puts "Jobs enqueued: #{summary[:enqueued_count]}"
    puts "Rows skipped: #{summary[:skipped_count]}"
    puts "Errors: #{summary[:error_count]}"

    if summary[:errors].any?
      puts "\nError details:"
      summary[:errors].each { |error| puts "- Line #{error[:line]}: #{error[:message]}" }
    end
  end

  desc "Import lectures from CSV file (async)"
  task :lectures, [ :file_path, :domain_id ] => :environment do |t, args|
    file_path = args[:file_path]
    domain_id = args[:domain_id]

    if file_path.nil? || file_path.empty? || domain_id.nil? || domain_id.empty?
      puts "Usage: rails import_resources:lectures[/path/to/file.csv,domain_id]"
      exit 1
    end

    puts "Processing CSV and enqueuing lecture import jobs from: #{file_path}"
    puts "Domain ID: #{domain_id}"

    processor = CsvImportProcessor.new(file_path, "LectureImportJob", domain_id.to_i)
    success = processor.process

    summary = processor.summary
    puts "CSV processing completed!"
    puts "Jobs enqueued: #{summary[:enqueued_count]}"
    puts "Rows skipped: #{summary[:skipped_count]}"
    puts "Errors: #{summary[:error_count]}"

    if summary[:errors].any?
      puts "\nError details:"
      summary[:errors].each { |error| puts "- Line #{error[:line]}: #{error[:message]}" }
    end

    unless success
      exit 1
    end
  end

  desc "Import lessons from CSV file (async)"
  task :lessons, [ :file_path, :domain_id ] => :environment do |t, args|
    file_path = args[:file_path]
    domain_id = args[:domain_id]

    if file_path.nil? || file_path.empty? || domain_id.nil? || domain_id.empty?
      puts "Usage: rails import_resources:lessons[/path/to/file.csv,domain_id]"
      exit 1
    end

    puts "Processing CSV and enqueuing lesson import jobs from: #{file_path}"
    puts "Domain ID: #{domain_id}"

    processor = CsvImportProcessor.new(file_path, "LessonImportJob", domain_id.to_i)
    success = processor.process

    summary = processor.summary
    puts "CSV processing completed!"
    puts "Jobs enqueued: #{summary[:enqueued_count]}"
    puts "Rows skipped: #{summary[:skipped_count]}"
    puts "Errors: #{summary[:error_count]}"

    if summary[:errors].any?
      puts "\nError details:"
      summary[:errors].each { |error| puts "- Line #{error[:line]}: #{error[:message]}" }
    end

    unless success
      exit 1
    end
  end

  desc "Import benefits from CSV file (async)"
  task :benefits, [ :file_path, :domain_id ] => :environment do |t, args|
    file_path = args[:file_path]
    domain_id = args[:domain_id]

    if file_path.nil? || file_path.empty? || domain_id.nil? || domain_id.empty?
      puts "Usage: rails import_resources:benefits[/path/to/file.csv,domain_id]"
      exit 1
    end

    puts "Processing CSV and enqueuing benefit import jobs from: #{file_path}"
    puts "Domain ID: #{domain_id}"

    processor = CsvImportProcessor.new(file_path, "BenefitImportJob", domain_id.to_i)
    success = processor.process

    summary = processor.summary
    puts "CSV processing completed!"
    puts "Jobs enqueued: #{summary[:enqueued_count]}"
    puts "Rows skipped: #{summary[:skipped_count]}"
    puts "Errors: #{summary[:error_count]}"

    if summary[:errors].any?
      puts "\nError details:"
      summary[:errors].each { |error| puts "- Line #{error[:line]}: #{error[:message]}" }
    end

    unless success
      exit 1
    end
  end

  desc "Import fatwas from CSV file (async)"
  task :fatwas, [ :file_path, :domain_id ] => :environment do |t, args|
    file_path = args[:file_path]
    domain_id = args[:domain_id]

    if file_path.nil? || file_path.empty? || domain_id.nil? || domain_id.empty?
      puts "Usage: rails import_resources:fatwas[/path/to/file.csv,domain_id]"
      exit 1
    end

    puts "Processing CSV and enqueuing fatwa import jobs from: #{file_path}"
    puts "Domain ID: #{domain_id}"

    processor = CsvImportProcessor.new(file_path, "FatwaImportJob", domain_id.to_i)
    success = processor.process

    summary = processor.summary
    puts "CSV processing completed!"
    puts "Jobs enqueued: #{summary[:enqueued_count]}"
    puts "Rows skipped: #{summary[:skipped_count]}"
    puts "Errors: #{summary[:error_count]}"

    if summary[:errors].any?
      puts "\nError details:"
      summary[:errors].each { |error| puts "- Line #{error[:line]}: #{error[:message]}" }
    end

    unless success
      exit 1
    end
  end

  desc "Display import template information"
  task info: :environment do
    puts "CSV Import System Information:"
    puts "=" * 50

    puts "CSV Templates directory: data/csv_templates/"
    puts "\nAvailable Templates:"
    puts "  • books_template.csv      - Islamic books and publications"
    puts "  • lectures_template.csv   - Audio/video lectures and talks"
    puts "  • lessons_template.csv    - Educational lessons (can be part of series)"
    puts "  • benefits_template.csv   - Short beneficial reminders"
    puts "  • fatwas_template.csv     - Religious rulings and Q&A"

    puts "\nUsage Examples:"
    puts "rails import_resources:books[/path/to/books.csv,domain_id]    # Import books (async jobs)"
    puts "rails import_resources:lectures[/path/to/lectures.csv,domain_id] # Import lectures (async jobs)"
    puts "rails import_resources:lessons[/path/to/lessons.csv,domain_id]   # Import lessons (async jobs)"
    puts "rails import_resources:benefits[/path/to/benefits.csv,domain_id] # Import benefits (async jobs)"
    puts "rails import_resources:fatwas[/path/to/fatwas.csv,domain_id]     # Import fatwas (async jobs)"
    puts "rails import_resources:info                                   # Show this information"
  end
end
