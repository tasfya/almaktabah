class ActiveStorageOrganizer
  all_content = Lesson.with_audio + Lecture.with_audio
  # TODO make sure this is happening after optimization
  def self.organize(contents)

    contents.find_each do |content|
      next unless content.audio&.attachment.present?

      key = content.generate_bucket_key
      blob = content.audio.attachment.blob
      next if key == blob.key
    end

    ActiveStorage::Blob.includes(:attachments).find_each do |blob|
      next unless blob.attachments.any?

      # Get the first attachment to determine the model
      attachment = blob.attachments.first
      record = attachment.record

      # Skip if no record or if it doesn't have the expected attributes
      next unless record.respond_to?(:scholar) && record.respond_to?(:id)

      old_key = blob.key
      new_key = generate_new_key(record, blob.filename.to_s)

      # Skip if keys are the same
      next if old_key == new_key
      copy_s3_object(old_key, new_key)

      begin
        # Copy object to new key
        copy_s3_object(old_key, new_key)

        # Update the blob record
        blob.update!(key: new_key)

        # Delete old object
        delete_s3_object(old_key)

        puts "Migrated: #{old_key} -> #{new_key}"

      rescue => e
        puts "Error migrating #{old_key}: #{e.message}"
        # Rollback: delete new key if it was created
        delete_s3_object(new_key) rescue nil
      end
    end
  end

  def self.s3_client
    @s3_client ||= Aws::S3::Client.new(
      access_key_id: bucket_config["access_key_id"],
      secret_access_key: bucket_config["secret_access_key"],
      region: bucket_config["region"],
      endpoint: bucket_config["endpoint"]
    )
  end

  def self.bucket_config
    service = Rails.application.config.active_storage.service
    Rails.application.config.active_storage.service_configurations[service.to_s]
  end

  def self.copy_s3_object(old_key, new_key)
    s3_client.copy_object(
      bucket: bucket_config["bucket"],
      copy_source: "#{bucket_name}/#{old_key}",
      key: new_key
    )
  end

  def self.delete_s3_object(key)
    s3_client.delete_object(
      bucket: bucket_name,
      key: key
    )
  end
end
