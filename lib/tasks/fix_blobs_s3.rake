namespace :blobs do
  desc "Fix ActiveStorage blobs missing file extensions by adding .mp3 (DB + S3)"
  task fix_missing_extension: :environment do
    puts "Starting to fix blobs without extension..."

    blobs_without_extension = ActiveStorage::Blob.where.not("filename LIKE '%.%'")
    puts "Found #{blobs_without_extension.count} blobs without extension."

    blobs_without_extension.find_each do |blob|
      old_key = blob.key
      old_filename = blob.filename.to_s

      next if old_filename.end_with?(".mp3") || old_key.end_with?(".mp3")

      new_filename = "#{old_filename}.mp3"
      new_key = "#{old_key}.mp3"

      service = blob.service

      unless service.is_a?(ActiveStorage::Service::S3Service)
        puts "Skipping blob id=#{blob.id}, not using S3 service"
        next
      end

      service.bucket.object(new_key).copy_from(
        copy_source: "#{service.bucket.name}/#{old_key}"
      )

      service.bucket.object(old_key).delete

      blob.update!(filename: new_filename, key: new_key)
      puts "Updated blob id=#{blob.id}: #{old_filename} -> #{new_filename}"
    rescue => e
      puts "Failed for blob id=#{blob.id}: #{e.message}"
    end
    puts "Done fixing blobs."
  end
end
