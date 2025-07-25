class ActiveStorageOrganizer
  all_content = Lesson.with_audio + Lecture.with_audio
  # TODO make sure this is happening after optimization
  def self.organize(contents)
    contents.each do |content|
      next unless content.optimized_audio&.attachment.present?

      old_key = content.generate_bucket_key
      blob = content.optimized_audio.attachment.blob
      next if old_key == blob.key

      copy_s3_object(old_key, new_key)
      blob.update!(key: new_key)
      delete_s3_object(old_key)
      puts "Migrated: #{old_key} -> #{new_key}"
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
