class Benefit < ApplicationRecord
    has_one_attached :thumbnail, service: Rails.application.config.public_storage
    has_one_attached :audio, service: Rails.application.config.public_storage
    has_one_attached :video, service: Rails.application.config.public_storage

    has_rich_text :content

    after_commit :set_duration, on: [ :create, :update ]
    validates :title, presence: true, length: { maximum: 255 }
    validates :description, presence: true, length: { maximum: 1000 }
    validates :category, presence: true

    def self.ransackable_attributes(auth_object = nil)
      [ "id", "title", "description", "category", "updated_at", "created_at" ]
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
      if video?
        I18n.t("common.video")
      elsif audio?
        I18n.t("common.audio")
      else
        nil
      end
    end

    private

    def set_duration
      MediaDurationExtractionJob.perform_later(self)
    end
end
