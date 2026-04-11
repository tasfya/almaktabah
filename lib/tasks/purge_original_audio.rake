# frozen_string_literal: true

namespace :audio do
  desc "Show stats for records with both audio and final_audio attached"
  task original_audio_stats: :environment do
    puts "Original Audio Cleanup Statistics"
    puts "=" * 60
    puts ""

    %w[Lecture Lesson Fatwa].each do |model_type|
      model_class = model_type.constantize

      # Records with both audio and final_audio
      with_both = model_class
        .joins(:audio_attachment)
        .joins(:final_audio_attachment)

      count = with_both.count

      if count.positive?
        # Calculate size of original audio
        blob_ids = ActiveStorage::Attachment
          .where(name: "audio", record_type: model_type, record_id: with_both.pluck(:id))
          .pluck(:blob_id)

        total_bytes = ActiveStorage::Blob.where(id: blob_ids).sum(:byte_size)
        total_mb = (total_bytes / 1_048_576.0).round(2)

        puts "#{model_type}: #{count} records (#{total_mb} MB of original audio)"
      else
        puts "#{model_type}: 0 records"
      end
    end

    puts ""
    puts "To purge original audio (with duration verification), run:"
    puts "  rake audio:purge_original_audio"
    puts ""
    puts "To purge for a specific model:"
    puts "  rake audio:purge_original_audio_for[Lecture]"
  end

  desc "Purge original audio for all records that have final_audio (with duration verification)"
  task purge_original_audio: :environment do
    puts "Purging Original Audio (with duration verification)"
    puts "=" * 60
    puts ""

    %w[Lecture Lesson Fatwa].each do |model_type|
      process_model(model_type)
    end
  end

  desc "Purge original audio for a specific model (e.g., rake audio:purge_original_audio_for[Lecture])"
  task :purge_original_audio_for, [ :model_type ] => :environment do |_task, args|
    model_type = args[:model_type]

    if model_type.blank?
      puts "Usage: rake audio:purge_original_audio_for[ModelName]"
      puts "Example: rake audio:purge_original_audio_for[Lecture]"
      exit 1
    end

    process_model(model_type)
  end

  desc "Enqueue background jobs to purge original audio for all records"
  task purge_original_audio_async: :environment do
    puts "Enqueuing Original Audio Purge Jobs"
    puts "=" * 60
    puts ""

    total_enqueued = 0

    %w[Lecture Lesson Fatwa].each do |model_type|
      model_class = model_type.constantize

      ids = model_class
        .joins(:audio_attachment)
        .joins(:final_audio_attachment)
        .pluck(:id)

      if ids.any?
        ids.each do |id|
          PurgeOriginalAudioJob.perform_later(model_type, id)
        end
        puts "#{model_type}: Enqueued #{ids.count} jobs"
        total_enqueued += ids.count
      else
        puts "#{model_type}: No records to process"
      end
    end

    puts ""
    puts "Total jobs enqueued: #{total_enqueued}"
    puts "Jobs will run in the background queue."
  end

  desc "Enqueue background jobs for a specific model"
  task :purge_original_audio_async_for, [ :model_type ] => :environment do |_task, args|
    model_type = args[:model_type]

    if model_type.blank?
      puts "Usage: rake audio:purge_original_audio_async_for[ModelName]"
      puts "Example: rake audio:purge_original_audio_async_for[Lecture]"
      exit 1
    end

    model_class = model_type.constantize

    ids = model_class
      .joins(:audio_attachment)
      .joins(:final_audio_attachment)
      .pluck(:id)

    if ids.empty?
      puts "No #{model_type} records with both audio and final_audio found."
      exit 0
    end

    puts "Enqueuing #{ids.count} #{model_type} records for original audio purge..."

    ids.each do |id|
      PurgeOriginalAudioJob.perform_later(model_type, id)
    end

    puts "Done! Jobs enqueued: #{ids.count}"
  end

  private

  def process_model(model_type)
    model_class = model_type.constantize

    records = model_class
      .joins(:audio_attachment)
      .joins(:final_audio_attachment)

    total = records.count

    if total.zero?
      puts "#{model_type}: No records with both audio and final_audio found."
      puts ""
      return
    end

    puts "#{model_type}: Processing #{total} records..."

    purged = 0
    skipped = 0
    errors = 0

    records.find_each.with_index do |record, index|
      print "\r  Processing: #{index + 1}/#{total}"

      result = verify_and_purge(record)

      case result
      when :purged
        purged += 1
      when :skipped
        skipped += 1
      when :error
        errors += 1
      end
    end

    puts ""
    puts "  Results: #{purged} purged, #{skipped} skipped (duration mismatch), #{errors} errors"
    puts ""
  end

  def verify_and_purge(record)
    # Get original audio duration
    original_duration = nil
    record.audio.open do |audio_file|
      temp = Tempfile.new([ "original", File.extname(record.audio.filename.to_s) ])
      begin
        temp.binmode
        temp.write(audio_file.read)
        temp.rewind
        original_duration = extract_duration(temp.path)
      ensure
        temp.close
        temp.unlink
      end
    end

    return :error unless original_duration

    # Get final audio duration
    final_duration = nil
    record.final_audio.open do |final_file|
      temp = Tempfile.new([ "final", ".mp3" ])
      begin
        temp.binmode
        temp.write(final_file.read)
        temp.rewind
        final_duration = extract_duration(temp.path)
      ensure
        temp.close
        temp.unlink
      end
    end

    return :error unless final_duration

    # Compare durations (1 second tolerance)
    duration_diff = (original_duration - final_duration).abs

    if duration_diff <= 1.0
      record.audio.purge
      :purged
    else
      Rails.logger.warn "Duration mismatch for #{record.class.name} ##{record.id}: original=#{original_duration}s, final=#{final_duration}s"
      :skipped
    end
  rescue => e
    Rails.logger.error "Error processing #{record.class.name} ##{record.id}: #{e.message}"
    :error
  end

  def extract_duration(file_path)
    movie = FFMPEG::Movie.new(file_path)
    movie.duration
  rescue => e
    Rails.logger.warn "Failed to extract duration from #{file_path}: #{e.message}"
    nil
  end
end
