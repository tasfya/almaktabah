# frozen_string_literal: true

def format_duration(seconds)
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
  desc "Analyze MP3 files for half-duplicates (dry run)"
  task :deduplicate_analyze, [ :input_folder ] => :environment do |_task, args|
    input_folder = args[:input_folder]

    if input_folder.blank?
      puts "Usage: rake audio:deduplicate_analyze[input_folder]"
      puts "Example: rake audio:deduplicate_analyze['/path/to/mp3/files']"
      exit 1
    end

    begin
      puts "MP3 Half-Duplication Analyzer"
      puts "Input folder: #{input_folder}"
      puts "Mode: DRY RUN (analysis only)"
      puts ""

      service = AudioDeduplicationService.new
      result = service.analyze_folder(input_folder)

      if result[:duplicates_found].positive?
        puts "\n🎯 Found #{result[:duplicates_found]} files with duplicates!"
        puts "Run the processing task to clean them:"
        puts "rake audio:deduplicate_process['#{input_folder}','/path/to/output/folder']"
      else
        puts "\n✨ All files are clean - no duplicates found!"
      end
    rescue AudioDeduplicationService::ProcessingError => e
      puts "❌ Error: #{e.message}"
      exit 1
    rescue StandardError => e
      puts "❌ Unexpected error: #{e.message}"
      puts e.backtrace.join("\n") if Rails.env.development?
      exit 1
    end
  end

  desc "Process MP3 files to remove half-duplicates"
  task :deduplicate_process, %i[input_folder output_folder] => :environment do |_task, args|
    input_folder = args[:input_folder]
    output_folder = args[:output_folder]

    if input_folder.blank? || output_folder.blank?
      puts "Usage: rake audio:deduplicate_process[input_folder,output_folder]"
      puts "Example: rake audio:deduplicate_process['/path/to/mp3/files','/path/to/clean/files']"
      exit 1
    end

    begin
      puts "MP3 Half-Duplication Processor"
      puts "Input folder: #{input_folder}"
      puts "Output folder: #{output_folder}"
      puts "Mode: PROCESSING (will create cleaned files)"
      puts ""

      # Confirm processing
      print "This will process and potentially modify audio files. Continue? (y/N): "
      confirmation = $stdin.gets.chomp.downcase

      unless %w[y yes].include?(confirmation)
        puts "Processing cancelled."
        exit 0
      end

      service = AudioDeduplicationService.new
      result = service.process_folder(input_folder, output_folder)

      puts "\n🎉 Processing completed!"
      puts "Files processed: #{result[:processed]}/#{result[:total_files]}"
      puts "Duplicates cleaned: #{result[:duplicates_found]}"
    rescue AudioDeduplicationService::ProcessingError => e
      puts "❌ Error: #{e.message}"
      exit 1
    rescue StandardError => e
      puts "❌ Unexpected error: #{e.message}"
      puts e.backtrace.join("\n") if Rails.env.development?
      exit 1
    end
  end

  desc "Analyze a specific record's audio for duplication"
  task :analyze_record, %i[model_type record_id] => :environment do |_task, args|
    model_type = args[:model_type]
    record_id = args[:record_id]

    if model_type.blank? || record_id.blank?
      puts "Usage: rake audio:analyze_record[Model,id]"
      puts "Example: rake audio:analyze_record[Lecture,123]"
      exit 1
    end

    begin
      model_class = model_type.constantize
      record = model_class.find(record_id)

      puts "Analyzing #{model_type} ##{record_id}: #{record.try(:title) || 'Untitled'}"
      puts ""

      service = AudioDeduplicationService.new

      %i[audio final_audio].each do |attachment_name|
        next unless record.respond_to?(attachment_name) && record.send(attachment_name).attached?

        puts "Checking #{attachment_name}..."
        attachment = record.send(attachment_name)

        # Download to temp file for analysis
        temp_file = Tempfile.new([ "audio_analysis", ".mp3" ])
        begin
          temp_file.binmode
          temp_file.write(attachment.download)
          temp_file.rewind

          analysis = service.analyze_file(temp_file.path)

          if analysis[:is_duplicate]
            puts "  [DUPLICATE DETECTED]"
            puts "    Current duration: #{format_duration(analysis[:duration])}"
            puts "    Estimated clean duration: #{format_duration(analysis[:clean_duration])}"
            puts "    Repeat factor: #{analysis[:repeat_factor]}x"
            puts ""
            puts "  To fix this record, run:"
            puts "    rake audio:fix_record[#{model_type},#{record_id},#{attachment_name}]"
          else
            puts "  [OK] Duration: #{format_duration(analysis[:duration])} - No duplication detected"
          end
        ensure
          temp_file.close
          temp_file.unlink
        end
      end
    rescue ActiveRecord::RecordNotFound
      puts "Record not found: #{model_type} ##{record_id}"
      exit 1
    rescue StandardError => e
      puts "Error: #{e.message}"
      puts e.backtrace.join("\n") if Rails.env.development?
      exit 1
    end
  end

  desc "Fix a specific record's duplicated audio"
  task :fix_record, %i[model_type record_id attachment_name] => :environment do |_task, args|
    model_type = args[:model_type]
    record_id = args[:record_id]
    attachment_name = args[:attachment_name]&.to_sym || :audio

    if model_type.blank? || record_id.blank?
      puts "Usage: rake audio:fix_record[Model,id,attachment_name]"
      puts "Example: rake audio:fix_record[Lecture,123,audio]"
      puts "Attachment names: audio, final_audio"
      exit 1
    end

    begin
      model_class = model_type.constantize
      record = model_class.find(record_id)

      unless record.respond_to?(attachment_name) && record.send(attachment_name).attached?
        puts "Record doesn't have #{attachment_name} attached"
        exit 1
      end

      puts "Processing #{model_type} ##{record_id}: #{record.try(:title) || 'Untitled'}"
      puts "Attachment: #{attachment_name}"
      puts ""

      service = AudioDeduplicationService.new
      attachment = record.send(attachment_name)

      # Download to temp file
      temp_input = Tempfile.new([ "audio_input", ".mp3" ])
      temp_output = Tempfile.new([ "audio_output", ".mp3" ])

      begin
        temp_input.binmode
        temp_input.write(attachment.download)
        temp_input.rewind

        analysis = service.analyze_file(temp_input.path)

        unless analysis[:is_duplicate]
          puts "No duplication detected in this file."
          exit 0
        end

        puts "Duplication detected!"
        puts "  Current duration: #{format_duration(analysis[:duration])}"
        puts "  Clean duration: #{format_duration(analysis[:clean_duration])}"
        puts "  Repeat factor: #{analysis[:repeat_factor]}x"
        puts ""

        print "Proceed with fix? (y/N): "
        confirmation = $stdin.gets.chomp.downcase
        unless %w[y yes].include?(confirmation)
          puts "Cancelled."
          exit 0
        end

        # Trim the audio
        puts "Trimming audio..."
        cmd = [
          "ffmpeg", "-y",
          "-i", temp_input.path,
          "-t", analysis[:clean_duration].to_s,
          "-c", "copy",
          temp_output.path
        ]
        system(*cmd, out: File::NULL, err: File::NULL)

        # Re-attach the trimmed file
        puts "Uploading trimmed file..."
        temp_output.rewind
        record.send(attachment_name).attach(
          io: File.open(temp_output.path),
          filename: attachment.filename.to_s,
          content_type: attachment.content_type
        )

        puts ""
        puts "Fixed! New duration: #{format_duration(analysis[:clean_duration])}"
      ensure
        temp_input.close
        temp_input.unlink
        temp_output.close
        temp_output.unlink
      end
    rescue ActiveRecord::RecordNotFound
      puts "Record not found: #{model_type} ##{record_id}"
      exit 1
    rescue StandardError => e
      puts "Error: #{e.message}"
      puts e.backtrace.join("\n") if Rails.env.development?
      exit 1
    end
  end

  desc "Scan all records of a model type for duplicated audio"
  task :scan_model, [ :model_type ] => :environment do |_task, args|
    model_type = args[:model_type]

    if model_type.blank?
      puts "Usage: rake audio:scan_model[Model]"
      puts "Example: rake audio:scan_model[Lecture]"
      puts "Supported models: Lecture, Lesson, Fatwa"
      exit 1
    end

    begin
      model_class = model_type.constantize
      service = AudioDeduplicationService.new

      puts "Scanning #{model_type} records for duplicated audio..."
      puts ""

      duplicates = []
      total = 0
      errors = 0

      # Find records with audio attached
      model_class.joins(:audio_attachment).find_each do |record|
        total += 1
        print "\rProcessed: #{total}"

        temp_file = Tempfile.new([ "scan", ".mp3" ])
        begin
          temp_file.binmode
          temp_file.write(record.audio.download)
          temp_file.rewind

          analysis = service.analyze_file(temp_file.path)

          if analysis[:is_duplicate]
            duplicates << {
              id: record.id,
              title: record.try(:title) || "Untitled",
              duration: analysis[:duration],
              clean_duration: analysis[:clean_duration],
              repeat_factor: analysis[:repeat_factor]
            }
          end
        rescue StandardError
          errors += 1
        ensure
          temp_file.close
          temp_file.unlink
        end
      end

      puts "\n\n"
      puts "=" * 60
      puts "Scan Results for #{model_type}"
      puts "=" * 60
      puts "Total records scanned: #{total}"
      puts "Duplicates found: #{duplicates.size}"
      puts "Errors: #{errors}"

      if duplicates.any?
        puts ""
        puts "Duplicated records:"
        puts "-" * 60
        duplicates.each do |d|
          puts "ID: #{d[:id]}"
          puts "  Title: #{d[:title]}"
          puts "  Duration: #{format_duration(d[:duration])} -> #{format_duration(d[:clean_duration])} (#{d[:repeat_factor]}x)"
          puts ""
        end

        puts "To fix a specific record:"
        puts "  rake audio:fix_record[#{model_type},<id>,audio]"
      end
    rescue NameError
      puts "Unknown model: #{model_type}"
      exit 1
    rescue StandardError => e
      puts "Error: #{e.message}"
      exit 1
    end
  end

  desc "Flag all potential duplicates in a model for manual review (background job)"
  task :flag_duplicates, [ :model_type ] => :environment do |_task, args|
    model_type = args[:model_type]

    if model_type.blank?
      puts "Usage: rake audio:flag_duplicates[Model]"
      puts "Example: rake audio:flag_duplicates[Lecture]"
      puts "Supported models: Lecture, Lesson, Fatwa"
      exit 1
    end

    begin
      model_class = model_type.constantize
      pending_count = model_class.pending.joins(:audio_attachment).count

      puts "Enqueuing #{pending_count} #{model_type} records for duplicate checking..."
      AudioDuplicateFlaggingJob.perform_later(model_type)

      puts "Jobs enqueued! Check progress with:"
      puts "  rake audio:status_summary[#{model_type}]"
    rescue NameError
      puts "Unknown model: #{model_type}"
      exit 1
    end
  end

  desc "Flag all potential duplicates synchronously (blocking)"
  task :flag_duplicates_sync, [ :model_type ] => :environment do |_task, args|
    model_type = args[:model_type]

    if model_type.blank?
      puts "Usage: rake audio:flag_duplicates_sync[Model]"
      puts "Example: rake audio:flag_duplicates_sync[Lecture]"
      puts "Supported models: Lecture, Lesson, Fatwa"
      exit 1
    end

    begin
      model_class = model_type.constantize
      service = AudioDeduplicationService.new

      puts "Scanning #{model_type} records and flagging potential duplicates..."
      puts ""

      total = 0
      flagged_count = 0
      errors = 0

      model_class.pending.joins(:audio_attachment).find_each do |record|
        total += 1
        print "\rProcessed: #{total}"

        temp_file = Tempfile.new([ "scan", ".mp3" ])
        begin
          temp_file.binmode
          temp_file.write(record.audio.download)
          temp_file.rewind

          analysis = service.analyze_file(temp_file.path)

          if analysis[:is_duplicate]
            record.flagged!
            flagged_count += 1
          end
        rescue StandardError
          errors += 1
        ensure
          temp_file.close
          temp_file.unlink
        end
      end

      puts "\n\n"
      puts "=" * 60
      puts "Flagging Results for #{model_type}"
      puts "=" * 60
      puts "Total records scanned: #{total}"
      puts "Records flagged: #{flagged_count}"
      puts "Errors: #{errors}"
      puts ""
      puts "To review flagged records:"
      puts "  rake audio:list_flagged[#{model_type}]"
    rescue NameError
      puts "Unknown model: #{model_type}"
      exit 1
    rescue StandardError => e
      puts "Error: #{e.message}"
      exit 1
    end
  end

  desc "List all flagged records for manual review"
  task :list_flagged, [ :model_type ] => :environment do |_task, args|
    model_type = args[:model_type]

    if model_type.blank?
      puts "Usage: rake audio:list_flagged[Model]"
      puts "Example: rake audio:list_flagged[Lecture]"
      exit 1
    end

    begin
      model_class = model_type.constantize
      flagged = model_class.flagged.joins(:audio_attachment)

      puts "Flagged #{model_type} records (#{flagged.count} total):"
      puts "=" * 60

      flagged.find_each do |record|
        duration = record.duration || "unknown"
        puts "ID: #{record.id} | #{record.try(:title) || 'Untitled'} | Duration: #{duration}s"
      end

      puts ""
      puts "Commands:"
      puts "  rake audio:mark_verified[#{model_type},<id>]   - Mark as not duplicate"
      puts "  rake audio:mark_duplicate[#{model_type},<id>]  - Confirm as duplicate"
      puts "  rake audio:fix_record[#{model_type},<id>,audio] - Auto-fix duplicate"
    rescue NameError
      puts "Unknown model: #{model_type}"
      exit 1
    end
  end

  desc "Mark a record as verified (not a duplicate)"
  task :mark_verified, %i[model_type record_id] => :environment do |_task, args|
    model_type = args[:model_type]
    record_id = args[:record_id]

    if model_type.blank? || record_id.blank?
      puts "Usage: rake audio:mark_verified[Model,id]"
      puts "Example: rake audio:mark_verified[Lecture,123]"
      exit 1
    end

    begin
      model_class = model_type.constantize
      record = model_class.find(record_id)
      record.verified!
      puts "Marked #{model_type} ##{record_id} as verified (not a duplicate)"
    rescue ActiveRecord::RecordNotFound
      puts "Record not found: #{model_type} ##{record_id}"
      exit 1
    end
  end

  desc "Mark a record as confirmed duplicate"
  task :mark_duplicate, %i[model_type record_id] => :environment do |_task, args|
    model_type = args[:model_type]
    record_id = args[:record_id]

    if model_type.blank? || record_id.blank?
      puts "Usage: rake audio:mark_duplicate[Model,id]"
      puts "Example: rake audio:mark_duplicate[Lecture,123]"
      exit 1
    end

    begin
      model_class = model_type.constantize
      record = model_class.find(record_id)
      record.duplicate!
      puts "Marked #{model_type} ##{record_id} as duplicate"
      puts "To auto-fix: rake audio:fix_record[#{model_type},#{record_id},audio]"
    rescue ActiveRecord::RecordNotFound
      puts "Record not found: #{model_type} ##{record_id}"
      exit 1
    end
  end

  desc "Show audio review status summary for a model"
  task :status_summary, [ :model_type ] => :environment do |_task, args|
    model_type = args[:model_type]

    if model_type.blank?
      puts "Usage: rake audio:status_summary[Model]"
      puts "Example: rake audio:status_summary[Lecture]"
      exit 1
    end

    begin
      model_class = model_type.constantize
      with_audio = model_class.joins(:audio_attachment)

      puts "Audio Review Status for #{model_type}"
      puts "=" * 40
      puts "Total with audio: #{with_audio.count}"
      puts "  Pending:    #{with_audio.pending.count}"
      puts "  Flagged:    #{with_audio.flagged.count}"
      puts "  Verified:   #{with_audio.verified.count}"
      puts "  Duplicate:  #{with_audio.duplicate.count}"
    rescue NameError
      puts "Unknown model: #{model_type}"
      exit 1
    end
  end

  desc "Configure deduplication settings"
  task :deduplicate_config do
    puts "MP3 Deduplication Configuration"
    puts "=" * 40
    puts "Current settings:"
    puts "  Similarity threshold: #{AudioDeduplicationService::DEFAULT_THRESHOLD} (#{(AudioDeduplicationService::DEFAULT_THRESHOLD * 100).round(1)}%)"
    puts "  Minimum duration: #{AudioDeduplicationService::DEFAULT_MIN_DURATION} seconds"
    puts ""
    puts "To modify these settings, edit the service class:"
    puts "  lib/services/audio_deduplication_service.rb"
    puts ""
    puts "Available tasks:"
    puts "  rake audio:deduplicate_analyze[folder]     - Analyze files (dry run)"
    puts "  rake audio:deduplicate_process[in,out]     - Process and clean files"
    puts "  rake audio:deduplicate_config              - Show this configuration"
  end
end
