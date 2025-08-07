class Benefit < ApplicationRecord
    include Publishable
    include MediaHandler
    include DomainAssignable
    include ArabicSluggable

    belongs_to :scholar, optional: true

    has_one_attached :thumbnail, service: Rails.application.config.public_storage
    has_one_attached :audio, service: Rails.application.config.public_storage
    has_one_attached :video, service: Rails.application.config.public_storage
    has_one_attached :optimized_audio, service: Rails.application.config.public_storage


    has_rich_text :content

    after_commit :set_duration, on: [ :create, :update ]
    validates :title, presence: true, length: { maximum: 255 }
    validates :description, presence: true, length: { maximum: 1000 }

    def self.ransackable_attributes(auth_object = nil)
      [ "id", "title", "description", "category", "published", "published_at", "scholar_id", "updated_at", "created_at" ]
    end

    def self.ransackable_associations(auth_object = nil)
      [ "scholar" ]
    end

    def generate_bucket_key(prefix: nil)
      slug = slugify_arabic_advanced(title)
      scholar_slug = scholar&.name ? slugify_arabic_advanced(scholar.name) : "unknown-scholar"
      ext = audio.attachment.blob.filename.extension

      base_key = if prefix
        "#{prefix}/scholars/#{scholar_slug}/benefits/#{slug}.#{ext}"
      else
        "scholars/#{scholar_slug}/benefits/#{slug}.#{ext}"
      end

      ensure_unique_key(base_key)
    end

    private

    def ensure_unique_key(key)
      return key unless ActiveStorage::Blob.exists?(key: key)

      counter = 1
      loop do
        name_part, extension = key.rsplit(".", 2)
        new_key = "#{name_part}_#{counter}.#{extension}"
        return new_key unless ActiveStorage::Blob.exists?(key: new_key)
        counter += 1
      end
    end

    private

    def set_duration
      MediaDurationExtractionJob.perform_later(self)
    end
end
