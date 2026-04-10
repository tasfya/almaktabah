# frozen_string_literal: true

namespace :storage do
  desc "List orphaned files in S3 bucket (files not referenced in ActiveStorage)"
  task s3_orphans_stats: :environment do
    service_name = ENV.fetch("SERVICE", "public_media_hetzner").to_sym
    prefix = ENV.fetch("PREFIX", "")

    puts "Scanning S3 bucket for orphaned files..."
    puts "Service: #{service_name}"
    puts "Prefix: #{prefix.presence || '(root)'}"
    puts ""

    service = ActiveStorage::Blob.services.fetch(service_name)

    unless service.respond_to?(:bucket)
      puts "Error: Service '#{service_name}' is not an S3 service"
      exit 1
    end

    bucket = service.bucket
    puts "Bucket: #{bucket.name}"
    puts ""

    # Get all keys from S3
    puts "Fetching objects from S3..."
    s3_keys = Set.new
    total_size = 0

    bucket.objects(prefix: prefix.presence).each do |obj|
      s3_keys << obj.key
      total_size += obj.size
    end

    puts "Found #{s3_keys.size} objects in S3 (#{format_size(total_size)})"

    # Get all blob keys from database for this service
    puts "Fetching blob keys from database..."
    db_keys = Set.new(
      ActiveStorage::Blob.where(service_name: service_name).pluck(:key)
    )
    puts "Found #{db_keys.size} blobs in database"

    # Find orphans
    orphan_keys = s3_keys - db_keys
    puts ""
    puts "=" * 60
    puts "Orphaned files (in S3 but not in database): #{orphan_keys.size}"

    if orphan_keys.any?
      # Calculate orphan size
      orphan_size = 0
      bucket.objects(prefix: prefix.presence).each do |obj|
        orphan_size += obj.size if orphan_keys.include?(obj.key)
      end

      puts "Orphaned size: #{format_size(orphan_size)}"
      puts ""

      # Show sample
      sample = orphan_keys.first(20)
      puts "Sample orphaned keys:"
      sample.each { |key| puts "  - #{key}" }
      puts "  ... and #{orphan_keys.size - 20} more" if orphan_keys.size > 20

      puts ""
      puts "To delete orphaned files, run:"
      puts "  rake storage:s3_purge_orphans SERVICE=#{service_name}"
      puts ""
      puts "To export list to CSV:"
      puts "  rake storage:s3_orphans_export SERVICE=#{service_name}"
    else
      puts "No orphaned files found!"
    end
  end

  desc "Export orphaned S3 files to CSV"
  task s3_orphans_export: :environment do
    require "csv"

    service_name = ENV.fetch("SERVICE", "public_media_hetzner").to_sym
    prefix = ENV.fetch("PREFIX", "")
    output_file = ENV.fetch("OUTPUT", "s3_orphans_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv")

    service = ActiveStorage::Blob.services.fetch(service_name)

    unless service.respond_to?(:bucket)
      puts "Error: Service '#{service_name}' is not an S3 service"
      exit 1
    end

    bucket = service.bucket

    puts "Fetching objects from S3..."
    s3_objects = {}
    bucket.objects(prefix: prefix.presence).each do |obj|
      s3_objects[obj.key] = { size: obj.size, last_modified: obj.last_modified }
    end

    puts "Fetching blob keys from database..."
    db_keys = Set.new(
      ActiveStorage::Blob.where(service_name: service_name).pluck(:key)
    )

    orphan_keys = s3_objects.keys.to_set - db_keys

    puts "Exporting #{orphan_keys.size} orphaned files to #{output_file}..."

    CSV.open(output_file, "w") do |csv|
      csv << [ "key", "size_bytes", "size_human", "last_modified" ]

      orphan_keys.each do |key|
        obj = s3_objects[key]
        csv << [ key, obj[:size], format_size(obj[:size]), obj[:last_modified] ]
      end
    end

    puts "Done! Exported to #{output_file}"
  end

  desc "Delete orphaned files from S3 bucket"
  task s3_purge_orphans: :environment do
    service_name = ENV.fetch("SERVICE", "public_media_hetzner").to_sym
    prefix = ENV.fetch("PREFIX", "")
    batch_size = ENV.fetch("BATCH_SIZE", "1000").to_i
    dry_run = ENV.fetch("DRY_RUN", "false") == "true"

    service = ActiveStorage::Blob.services.fetch(service_name)

    unless service.respond_to?(:bucket)
      puts "Error: Service '#{service_name}' is not an S3 service"
      exit 1
    end

    bucket = service.bucket

    puts "S3 Orphan Cleanup"
    puts "=" * 60
    puts "Service: #{service_name}"
    puts "Bucket: #{bucket.name}"
    puts "Prefix: #{prefix.presence || '(root)'}"
    puts "Mode: #{dry_run ? 'DRY RUN' : 'DELETE'}"
    puts ""

    # Get all keys from S3
    puts "Fetching objects from S3..."
    s3_objects = {}
    bucket.objects(prefix: prefix.presence).each do |obj|
      s3_objects[obj.key] = obj
    end
    puts "Found #{s3_objects.size} objects"

    # Get all blob keys from database
    puts "Fetching blob keys from database..."
    db_keys = Set.new(
      ActiveStorage::Blob.where(service_name: service_name).pluck(:key)
    )
    puts "Found #{db_keys.size} blobs in database"

    # Find orphans
    orphan_keys = s3_objects.keys.to_set - db_keys
    orphan_size = orphan_keys.sum { |key| s3_objects[key].size }

    puts ""
    puts "Orphaned files: #{orphan_keys.size} (#{format_size(orphan_size)})"

    if orphan_keys.empty?
      puts "No orphaned files to delete."
      exit 0
    end

    unless dry_run
      puts ""
      print "This will PERMANENTLY DELETE #{orphan_keys.size} files. Continue? (y/N): "
      confirmation = $stdin.gets.chomp.downcase

      unless %w[y yes].include?(confirmation)
        puts "Cancelled."
        exit 0
      end
    end

    puts ""
    puts "Processing..."

    deleted = 0
    errors = 0
    orphan_keys_array = orphan_keys.to_a

    # Delete in batches
    orphan_keys_array.each_slice(batch_size) do |batch|
      if dry_run
        batch.each do |key|
          puts "[DRY RUN] Would delete: #{key}"
          deleted += 1
        end
      else
        begin
          # Use batch delete for efficiency
          objects_to_delete = batch.map { |key| { key: key } }
          bucket.delete_objects(delete: { objects: objects_to_delete })
          deleted += batch.size
          print "\rDeleted: #{deleted}/#{orphan_keys.size}"
        rescue => e
          errors += batch.size
          Rails.logger.error "Batch delete failed: #{e.message}"

          # Fall back to individual deletes
          batch.each do |key|
            begin
              s3_objects[key].delete
              deleted += 1
            rescue => e2
              errors += 1
              Rails.logger.error "Failed to delete #{key}: #{e2.message}"
            end
          end
        end
      end
    end

    puts ""
    puts ""
    puts "=" * 60
    puts "Cleanup completed!"
    puts "  Deleted: #{deleted}"
    puts "  Errors: #{errors}"
    puts "  Space freed: #{format_size(orphan_size)}" unless dry_run
  end

  desc "Find files in S3 matching a pattern"
  task :s3_find, [ :pattern ] => :environment do |_task, args|
    pattern = args[:pattern]
    service_name = ENV.fetch("SERVICE", "public_media_hetzner").to_sym

    if pattern.blank?
      puts "Usage: rake storage:s3_find[pattern] SERVICE=service_name"
      puts "Example: rake storage:s3_find[optimized] SERVICE=public_media_hetzner"
      exit 1
    end

    service = ActiveStorage::Blob.services.fetch(service_name)

    unless service.respond_to?(:bucket)
      puts "Error: Service '#{service_name}' is not an S3 service"
      exit 1
    end

    bucket = service.bucket
    regex = Regexp.new(pattern, Regexp::IGNORECASE)

    puts "Searching for files matching '#{pattern}' in #{service_name}..."
    puts ""

    matches = []
    total_size = 0

    bucket.objects.each do |obj|
      if obj.key.match?(regex)
        matches << { key: obj.key, size: obj.size, last_modified: obj.last_modified }
        total_size += obj.size
      end
    end

    if matches.empty?
      puts "No files found matching '#{pattern}'"
    else
      puts "Found #{matches.size} files (#{format_size(total_size)}):"
      puts ""

      matches.first(50).each do |m|
        puts "  #{m[:key]} (#{format_size(m[:size])})"
      end

      puts "  ... and #{matches.size - 50} more" if matches.size > 50

      # Check which are in database
      match_keys = matches.map { |m| m[:key] }
      db_keys = ActiveStorage::Blob.where(key: match_keys).pluck(:key).to_set

      orphans = match_keys.reject { |k| db_keys.include?(k) }
      puts ""
      puts "In database: #{db_keys.size}"
      puts "Orphaned: #{orphans.size}"
    end
  end

  private

  def format_size(bytes)
    if bytes >= 1_073_741_824
      "#{(bytes / 1_073_741_824.0).round(2)} GB"
    elsif bytes >= 1_048_576
      "#{(bytes / 1_048_576.0).round(2)} MB"
    elsif bytes >= 1024
      "#{(bytes / 1024.0).round(2)} KB"
    else
      "#{bytes} bytes"
    end
  end
end

def format_size(bytes)
  if bytes >= 1_073_741_824
    "#{(bytes / 1_073_741_824.0).round(2)} GB"
  elsif bytes >= 1_048_576
    "#{(bytes / 1_048_576.0).round(2)} MB"
  elsif bytes >= 1024
    "#{(bytes / 1024.0).round(2)} KB"
  else
    "#{bytes} bytes"
  end
end
