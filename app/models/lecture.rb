class Lecture < ApplicationRecord
    validates :title, presence: true, uniqueness: true
    validates :old_id, uniqueness: true, allow_nil: true

    has_one_attached :thumbnail, service: Rails.application.config.public_storage
    has_one_attached :audio, service: Rails.application.config.public_storage
    has_one_attached :video, service: Rails.application.config.public_storage
    has_rich_text :content

    def video?
      video_url.present?
    end

    def audio?
      audio.attached?
    end
end
