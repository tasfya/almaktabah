# frozen_string_literal: true

# Helper to format duration in human-readable format
def format_audio_duration(seconds)
  return "?" unless seconds
  hours = (seconds / 3600).to_i
  minutes = ((seconds % 3600) / 60).to_i
  secs = (seconds % 60).to_i
  if hours > 0
    format("%d:%02d:%02d", hours, minutes, secs)
  else
    format("%d:%02d", minutes, secs)
  end
end

namespace :audio do
  desc "Fix audio imports from CSV by re-downloading and comparing durations"
  task :fix_imports, [ :csv_path, :model_type, :domain_id ] => :environment do |_t, args|
    require "csv"

    csv_path = args[:csv_path]
    model_type = args[:model_type] || "lecture"
    domain_id = args[:domain_id]
    force = ENV["FORCE"].present?

    unless csv_path && File.exist?(csv_path)
      puts "Usage: rake audio:fix_imports[path/to/file.csv,model_type,domain_id]"
      puts "  csv_path: Path to CSV file (required)"
      puts "  model_type: lecture, lesson, or fatwa (default: lecture)"
      puts "  domain_id: Optional domain ID"
      puts ""
      puts "Options (via environment variables):"
      puts "  FORCE=1  Re-check all records, even those already verified"
      puts ""
      puts "Examples:"
      puts "  rake audio:fix_imports[imports/lectures.csv,lecture]"
      puts "  FORCE=1 rake audio:fix_imports[imports/lectures.csv,lecture]"
      exit 1
    end

    puts "=" * 60
    puts "Audio Import Fixer"
    puts "=" * 60
    puts "CSV File: #{csv_path}"
    puts "Model Type: #{model_type}"
    puts "Domain ID: #{domain_id || 'none'}"
    puts "Force: #{force ? 'yes (re-checking all)' : 'no (skipping verified)'}"
    puts "=" * 60

    csv_content = File.read(csv_path)
    csv = CSV.parse(csv_content, headers: true)

    total = csv.count
    skipped_no_url = 0
    skipped_other = 0
    verified = 0
    fixed = []
    failed = []

    progress = ProgressBar.create(
      title: "Processing",
      total: total,
      format: "%t: |%B| %c/%C (%p%%) %e"
    )

    csv.each.with_index(1) do |row, line_number|
      row_data = row.to_h

      # Skip rows without audio URL
      if row_data["audio_file_url"].blank?
        skipped_no_url += 1
        progress.increment
        next
      end

      begin
        result = AudioImportFixerJob.perform_now(row_data, model_type, domain_id, line_number, force: force)

        case result&.status
        when :fixed
          fixed << result
        when :verified
          verified += 1
        when :skipped
          skipped_other += 1
        end
      rescue => e
        failed << { line: line_number, title: row_data["title"], error: e.message }
        puts "\nError on line #{line_number}: #{e.message}"
      end

      progress.increment
    end

    puts ""
    puts "=" * 60
    puts "Summary"
    puts "=" * 60
    puts "Total rows: #{total}"
    puts "Verified (durations match): #{verified}"
    puts "Fixed (duration mismatch): #{fixed.size}"
    puts "Skipped (no audio URL): #{skipped_no_url}"
    puts "Skipped (other reasons): #{skipped_other}"
    puts "Failed: #{failed.size}"

    if fixed.any?
      puts ""
      puts "=" * 60
      puts "Fixed Records"
      puts "=" * 60
      fixed.each do |result|
        record = result.record
        old_dur = result.old_duration ? format_audio_duration(result.old_duration) : "unknown"
        new_dur = result.new_duration ? format_audio_duration(result.new_duration) : "unknown"
        puts "Line #{result.line_number}: #{record.class.name}##{record.id} - #{record.title}"
        puts "  Duration: #{old_dur} -> #{new_dur}"
      end
    end

    if failed.any?
      puts ""
      puts "=" * 60
      puts "Failed Records"
      puts "=" * 60
      failed.each do |f|
        puts "Line #{f[:line]}: #{f[:title]} - #{f[:error]}"
      end
    end
  end

  desc "Fix audio imports asynchronously (enqueues jobs)"
  task :fix_imports_async, [ :csv_path, :model_type, :domain_id ] => :environment do |_t, args|
    require "csv"

    csv_path = args[:csv_path]
    model_type = args[:model_type] || "lecture"
    domain_id = args[:domain_id]
    force = ENV["FORCE"].present?

    unless csv_path && File.exist?(csv_path)
      puts "Usage: rake audio:fix_imports_async[path/to/file.csv,model_type,domain_id]"
      puts ""
      puts "Options (via environment variables):"
      puts "  FORCE=1  Re-check all records, even those already verified"
      exit 1
    end

    puts "Force mode: #{force ? 'yes' : 'no'}"

    csv_content = File.read(csv_path)
    csv = CSV.parse(csv_content, headers: true)

    enqueued = 0

    csv.each.with_index(1) do |row, line_number|
      row_data = row.to_h

      next if row_data["audio_file_url"].blank?

      AudioImportFixerJob.perform_later(row_data, model_type, domain_id, line_number, force: force)
      enqueued += 1
    end

    puts "Enqueued #{enqueued} jobs for processing"
  end

  desc "Fix a single record's audio by re-downloading from source URL"
  task :fix_single, [ :model_type, :record_id, :audio_url ] => :environment do |_t, args|
    model_type = args[:model_type]
    record_id = args[:record_id]
    audio_url = args[:audio_url]
    force = ENV["FORCE"].present?

    unless model_type && record_id && audio_url
      puts "Usage: rake audio:fix_single[model_type,record_id,audio_url]"
      puts "  model_type: lecture, lesson, or fatwa"
      puts "  record_id: ID of the record"
      puts "  audio_url: URL to download audio from"
      puts ""
      puts "Options (via environment variables):"
      puts "  FORCE=1  Re-check even if already verified"
      puts ""
      puts "Examples:"
      puts "  rake audio:fix_single[lecture,123,https://example.com/audio.mp3]"
      puts "  FORCE=1 rake audio:fix_single[lecture,123,https://example.com/audio.mp3]"
      exit 1
    end

    model_class = case model_type.downcase
    when "lecture" then Lecture
    when "lesson" then Lesson
    when "fatwa" then Fatwa
    else
      puts "Unknown model type: #{model_type}"
      exit 1
    end

    record = model_class.find(record_id)
    puts "Found #{model_type}: #{record.title}"
    puts "Already verified: #{record.audio_verified_at || 'no'}"
    puts "Force: #{force ? 'yes' : 'no'}"

    # Build minimal row data for the job
    row_data = {
      "audio_file_url" => audio_url,
      "title" => record.title,
      "scholar_id" => record.scholar_id
    }

    # Add model-specific fields
    case model_type.downcase
    when "lecture"
      row_data["category"] = record.category
      row_data["kind"] = record.kind
    when "lesson"
      row_data["series_title"] = record.series&.title
    end

    AudioImportFixerJob.perform_now(row_data, model_type, nil, 1, force: force)
    puts "Done!"
  end

  desc "Reset audio_verified_at for all records (allows re-checking)"
  task :reset_verified, [ :model_type ] => :environment do |_t, args|
    model_type = args[:model_type]

    unless model_type
      puts "Usage: rake audio:reset_verified[model_type]"
      puts "  model_type: lecture, lesson, fatwa, or all"
      puts ""
      puts "Examples:"
      puts "  rake audio:reset_verified[lecture]"
      puts "  rake audio:reset_verified[all]"
      exit 1
    end

    models = case model_type.downcase
    when "lecture" then [ Lecture ]
    when "lesson" then [ Lesson ]
    when "fatwa" then [ Fatwa ]
    when "all" then [ Lecture, Lesson, Fatwa ]
    else
      puts "Unknown model type: #{model_type}"
      exit 1
    end

    models.each do |model_class|
      count = model_class.where.not(audio_verified_at: nil).count
      model_class.update_all(audio_verified_at: nil)
      puts "Reset #{count} #{model_class.name.pluralize}"
    end

    puts "Done! All records can now be re-checked."
  end

  desc "Show verification status for a model type"
  task :verification_status, [ :model_type ] => :environment do |_t, args|
    model_type = args[:model_type] || "all"

    models = case model_type.downcase
    when "lecture" then [ Lecture ]
    when "lesson" then [ Lesson ]
    when "fatwa" then [ Fatwa ]
    when "all" then [ Lecture, Lesson, Fatwa ]
    else
      puts "Unknown model type: #{model_type}"
      exit 1
    end

    puts "=" * 60
    puts "Audio Verification Status"
    puts "=" * 60

    models.each do |model_class|
      total = model_class.count
      with_audio = model_class.joins(:audio_attachment).count
      verified = model_class.where.not(audio_verified_at: nil).count
      unverified = with_audio - verified

      puts ""
      puts "#{model_class.name}:"
      puts "  Total records: #{total}"
      puts "  With audio: #{with_audio}"
      puts "  Verified: #{verified}"
      puts "  Unverified (with audio): #{unverified}"
    end
  end
end
