Rails.application.config.to_prepare do
  ActiveStorage::Blob.class_eval do
    before_create :set_custom_key

    def set_custom_key
      nil if key.present?

      if attachments.any? && attachments.first.record.respond_to?(:generate_bucket_key)
        record = attachments.first.record
        self.key = record.generate_bucket_key(attachment_name: attachments.first.name, extension: self.filename.extension)
      else
        self.key = SecureRandom.uuid
      end

      self.key = ensure_unique_key(self.key)
    end

    def ensure_unique_key(key)
      return key unless ActiveStorage::Blob.exists?(key: key)

      counter = 1
      loop do
        name_part, _, extension = key.rpartition(".")
        new_key = "#{name_part}_#{counter}.#{extension}"
        return new_key unless ActiveStorage::Blob.exists?(key: new_key)
        counter += 1
      end
    end
  end
end
