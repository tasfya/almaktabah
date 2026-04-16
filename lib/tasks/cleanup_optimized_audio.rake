# frozen_string_literal: true

namespace :storage do
  desc "List all optimized_audio attachments (dry run)"
  task optimized_audio_stats: :environment do
    attachments = ActiveStorage::Attachment.where(name: "optimized_audio")

    puts "Optimized Audio Attachments Statistics"
    puts "=" * 50
    puts ""

    # Group by record type
    by_type = attachments.group(:record_type).count
    by_type.each do |type, count|
      puts "  #{type}: #{count}"
    end

    puts ""
    puts "Total attachments: #{attachments.count}"

    # Calculate total size
    blob_ids = attachments.pluck(:blob_id)
    total_bytes = ActiveStorage::Blob.where(id: blob_ids).sum(:byte_size)
    total_gb = (total_bytes / 1_073_741_824.0).round(2)
    total_mb = (total_bytes / 1_048_576.0).round(2)

    puts "Total size: #{total_mb} MB (#{total_gb} GB)"
    puts ""
    puts "To delete these attachments, run:"
    puts "  rake storage:purge_optimized_audio"
  end

  desc "Purge all optimized_audio attachments and their blobs"
  task purge_optimized_audio: :environment do
    attachments = ActiveStorage::Attachment.where(name: "optimized_audio")
    total = attachments.count

    if total.zero?
      puts "No optimized_audio attachments found."
      exit 0
    end

    puts "Found #{total} optimized_audio attachments to purge."
    puts ""

    # Show breakdown
    by_type = attachments.group(:record_type).count
    by_type.each do |type, count|
      puts "  #{type}: #{count}"
    end

    puts ""
    print "This will permanently delete these attachments and their files. Continue? (y/N): "
    confirmation = $stdin.gets.chomp.downcase

    unless %w[y yes].include?(confirmation)
      puts "Cancelled."
      exit 0
    end

    puts ""
    puts "Purging attachments..."

    purged = 0
    errors = 0

    # Process in batches to avoid memory issues
    attachments.find_each do |attachment|
      begin
        # Purge the blob (deletes the file from storage and the blob record)
        attachment.purge
        purged += 1
        print "\rPurged: #{purged}/#{total}"
      rescue => e
        errors += 1
        Rails.logger.error "Failed to purge attachment #{attachment.id}: #{e.message}"
      end
    end

    puts ""
    puts ""
    puts "=" * 50
    puts "Purge completed!"
    puts "  Successfully purged: #{purged}"
    puts "  Errors: #{errors}"

    # Clean up orphaned blobs
    orphaned = ActiveStorage::Blob.left_joins(:attachments)
                                  .where(active_storage_attachments: { id: nil })
                                  .count

    if orphaned.positive?
      puts ""
      puts "Note: Found #{orphaned} orphaned blobs."
      puts "Run 'rake storage:purge_orphaned_blobs' to clean them up."
    end
  end

  desc "Purge orphaned blobs (blobs with no attachments)"
  task purge_orphaned_blobs: :environment do
    orphaned = ActiveStorage::Blob.left_joins(:attachments)
                                  .where(active_storage_attachments: { id: nil })

    total = orphaned.count

    if total.zero?
      puts "No orphaned blobs found."
      exit 0
    end

    total_bytes = orphaned.sum(:byte_size)
    total_mb = (total_bytes / 1_048_576.0).round(2)

    puts "Found #{total} orphaned blobs (#{total_mb} MB)"
    print "Purge these blobs? (y/N): "
    confirmation = $stdin.gets.chomp.downcase

    unless %w[y yes].include?(confirmation)
      puts "Cancelled."
      exit 0
    end

    puts "Purging..."

    purged = 0
    orphaned.find_each do |blob|
      blob.purge
      purged += 1
      print "\rPurged: #{purged}/#{total}"
    rescue => e
      Rails.logger.error "Failed to purge blob #{blob.id}: #{e.message}"
    end

    puts ""
    puts "Done! Purged #{purged} orphaned blobs."
  end

  desc "Purge optimized_audio for a specific model (e.g., rake storage:purge_optimized_audio_for[Lecture])"
  task :purge_optimized_audio_for, [ :model_type ] => :environment do |_task, args|
    model_type = args[:model_type]

    if model_type.blank?
      puts "Usage: rake storage:purge_optimized_audio_for[ModelName]"
      puts "Example: rake storage:purge_optimized_audio_for[Lecture]"
      exit 1
    end

    attachments = ActiveStorage::Attachment.where(name: "optimized_audio", record_type: model_type)
    total = attachments.count

    if total.zero?
      puts "No optimized_audio attachments found for #{model_type}."
      exit 0
    end

    # Calculate size
    blob_ids = attachments.pluck(:blob_id)
    total_bytes = ActiveStorage::Blob.where(id: blob_ids).sum(:byte_size)
    total_mb = (total_bytes / 1_048_576.0).round(2)

    puts "Found #{total} optimized_audio attachments for #{model_type} (#{total_mb} MB)"
    print "Purge these attachments? (y/N): "
    confirmation = $stdin.gets.chomp.downcase

    unless %w[y yes].include?(confirmation)
      puts "Cancelled."
      exit 0
    end

    puts "Purging..."

    purged = 0
    attachments.find_each do |attachment|
      attachment.purge
      purged += 1
      print "\rPurged: #{purged}/#{total}"
    rescue => e
      Rails.logger.error "Failed to purge attachment #{attachment.id}: #{e.message}"
    end

    puts ""
    puts "Done! Purged #{purged} attachments."
  end
end
