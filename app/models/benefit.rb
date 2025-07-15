class Benefit < ApplicationRecord
    include Publishable
    include MediaHandler
    include DomainAssignable

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

    private

    def set_duration
      MediaDurationExtractionJob.perform_later(self)
    end
end
