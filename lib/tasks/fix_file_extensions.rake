namespace :fix do
  desc "Fix file extensions and names for attachments in production. Pass dry_run=true to preview changes."
  task :fix_attachments, [ :dry_run ] => :environment do |t, args|
    # next unless Rails.env.production?

    dry_run = args[:dry_run] == "true"
    puts "Starting to fix attachments... (dry_run: #{dry_run})"

    changes_log = []

    def ensure_key_unique(desired_key)
      key = desired_key
      counter = 0
      while ActiveStorage::Blob.where(key: key).exists?
        base = desired_key.sub(/\.\w*$/, "")
        ext = File.extname(desired_key)
        key = "#{base}_#{counter}#{ext}"
        counter += 1
        break if counter > 10
      end
      key
    end

    ActiveStorage::Blob.find_each do |blob|
      original_filename = blob.filename.to_s

      if File.extname(original_filename).empty? || original_filename.end_with?(".")
        ext = case blob.content_type
        when "audio/mpeg", "audio/mp3" then ".mp3"
        when "audio/wav" then ".wav"
        when "audio/ogg" then ".ogg"
        when "video/mp4" then ".mp4"
        when "video/webm" then ".webm"
        when "image/jpeg" then ".jpg"
        when "image/png" then ".png"
        when "image/gif" then ".gif"
        when "application/pdf" then ".pdf"
        else ".bin" # fallback extension
        end

        # Clean up filename ending with a dot
        cleaned_filename = original_filename.chomp(".")
        new_filename = cleaned_filename + ext

        if dry_run
          puts "[DRY RUN] Would update filename for blob #{blob.id}: #{original_filename} -> #{new_filename}"
        else
          blob.update(filename: new_filename)
          puts "Updated filename for blob #{blob.id}: #{original_filename} -> #{new_filename}"
        end

        attachment = ActiveStorage::Attachment.find_by(blob: blob)
        next unless attachment

        record = attachment.record
        old_key = blob.key

        desired_key = case record.class.name
        when "Lesson", "Lecture"
                        if record.respond_to?(:generate_optimize_audio_bucket_key)
                          base_key = record.generate_optimize_audio_bucket_key.to_s
                          base_key.end_with?(ext) ? base_key : "#{base_key}#{ext}"
                        else
                          "#{old_key}#{ext}"
                        end
        when "Book"
                        "book-#{record.id}-#{attachment.name}#{ext}"
        else
                        "#{old_key}#{ext}"
        end

        new_key = ensure_key_unique(desired_key)

        next if old_key == new_key

        service = blob.service
        bucket_name = service.bucket.name

        if service.exist?(old_key)
          if dry_run
            puts "[DRY RUN] Would rename S3 key for blob #{blob.id}: #{old_key} -> #{new_key}"
          else
            begin
              service.client.copy_object(bucket: bucket_name, copy_source: "#{bucket_name}/#{old_key}", key: new_key)
              blob.update(key: new_key)
              service.client.delete_object(bucket: bucket_name, key: old_key)
              puts "Renamed S3 key for blob #{blob.id}: #{old_key} -> #{new_key}"

              changes_log << {
                blob_id: blob.id,
                old_filename: original_filename,
                new_filename: new_filename,
                old_key: old_key,
                new_key: new_key
              }
            rescue => e
              puts "Error updating S3 key for blob #{blob.id}: #{e.message}"
            end
          end
        else
          puts "S3 object not found for blob #{blob.id}, key: #{old_key}"
        end
      end
    end

    unless dry_run || changes_log.empty?
      log_file = Rails.root.join("log", "attachment_fixes.log")
      File.open(log_file, "a") do |f|
        f.puts "# Fix run at #{Time.current}"
        changes_log.each do |change|
          f.puts change.to_json
        end
        f.puts ""
      end
      puts "Changes logged to #{log_file}"
    end

    puts "Finished fixing attachments."
  end

  desc "Rollback attachment fixes based on the last log entry"
  task rollback_attachments: :environment do
    next unless Rails.env.production?

    log_file = Rails.root.join("log", "attachment_fixes.log")
    unless File.exist?(log_file)
      puts "No log file found at #{log_file}"
      next
    end

    lines = File.readlines(log_file).reverse
    changes = []
    lines.each do |line|
      break if line.start_with?("#") && !changes.empty?
      next if line.strip.empty? || line.start_with?("#")
      changes << JSON.parse(line)
    end

    if changes.empty?
      puts "No changes found in log to rollback."
      next
    end

    puts "Found #{changes.size} changes to rollback."

    changes.each do |change|
      blob = ActiveStorage::Blob.find_by(id: change["blob_id"])
      next unless blob

      old_key = change["old_key"]
      new_key = change["new_key"]
      old_filename = change["old_filename"]
      new_filename = change["new_filename"]

      service = blob.service
      bucket_name = service.bucket.name

      if service.exist?(new_key)
        begin
          service.client.copy_object(bucket: bucket_name, copy_source: "#{bucket_name}/#{new_key}", key: old_key)
          blob.update(key: old_key, filename: old_filename)
          service.client.delete_object(bucket: bucket_name, key: new_key)
          puts "Rolled back blob #{blob.id}: key #{new_key} -> #{old_key}, filename #{new_filename} -> #{old_filename}"
        rescue => e
          puts "Error rolling back blob #{blob.id}: #{e.message}"
        end
      else
        puts "New key not found for blob #{blob.id}, key: #{new_key}"
      end
    end

    puts "Finished rolling back attachments."
  end
end
