class Benefit < ApplicationRecord
    has_one_attached :thumbnail, service: Rails.application.config.public_storage
    has_one_attached :audio, service: Rails.application.config.public_storage
    has_one_attached :video, service: Rails.application.config.public_storage

    has_rich_text :content

    after_commit :set_duration, on: [ :create, :update ]

    # Ransack configuration
    def self.ransackable_attributes(auth_object = nil)
        [ "category", "created_at", "id", "title", "description", "updated_at" ]
    end

    def self.ransackable_associations(auth_object = nil)
        []
    end

    def audio?
      audio.attached?
    end

    def video?
      video.attached?
    end

    def media_type
      video? ? I18n.t("common.video") : I18n.t("common.audio")
    end

    private

    def set_duration
      MediaDurationExtractionJob.perform_later(self)
    end
end
