namespace :blobs do
  desc "Fix ActiveStorage blobs missing file extensions by adding .mp3 (DB + S3), skipping deleted records"
  task fix_missing_extension: :environment do
    puts "Starting to fix blobs without extension..."

    record_types = %w[Lecture Lesson Benefit]

    record_types.each do |record_type|
      attachments = ActiveStorage::Attachment.where(record_type: record_type)
      puts "Found #{attachments.count} attachments for #{record_type}..."

      attachments.each do |attachment|
        record_exists = record_type.constantize.where(id: attachment.record_id).exists?
        if !record_exists
          puts "Skipping attachment id=#{attachment.id}, associated record not found"
          next
        end

        blob = attachment.blob
        next unless blob

        old_filename = blob.filename.to_s
        old_key = blob.key

        next if old_filename.end_with?(".mp3") || old_key.end_with?(".mp3")

        cleaned_filename = old_filename.rstrip.chomp(".")
        cleaned_key      = old_key.rstrip.chomp(".")
        new_filename = "#{cleaned_filename}.mp3"
        new_key = "#{cleaned_key}.mp3"

        service = blob.service

        unless service.is_a?(ActiveStorage::Service::S3Service)
          puts "Skipping blob id=#{blob.id}, not using S3 service"
          next
        end

        begin
          service.bucket.object(new_key).copy_from(copy_source: "#{service.bucket.name}/#{old_key}")
          service.bucket.object(old_key).delete

          blob.update!(filename: new_filename, key: new_key)
          puts "Updated blob id=#{blob.id}: #{old_filename} -> #{new_filename}"
        rescue => e
          puts "Failed for blob id=#{blob.id}: #{e.message}"
        end
      end
    end

    puts "Done fixing blobs."
  end
end
