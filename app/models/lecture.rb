class Lecture < ApplicationRecord
  include MediaHandler

  validates :title, presence: true, uniqueness: true

  has_one_attached :thumbnail, service: Rails.application.config.public_storage
  has_one_attached :audio, service: Rails.application.config.public_storage
  has_one_attached :video, service: Rails.application.config.public_storage
  has_one_attached :optimized_audio, service: Rails.application.config.public_storage
  has_rich_text :content

    # Scopes
    scope :recent, -> { order(published_date: :desc) }
    scope :most_viewed, -> { order(views: :desc) }
    scope :by_category, ->(category) { where(category: category) if category.present? }

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "category", "created_at", "description", "duration", "id", "published_date", "speaker", "title", "updated_at", "views" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "speaker" ]
  end

    def audio_url
      return nil unless audio.attached?
      Rails.application.routes.url_helpers.rails_blob_url(audio, only_path: true)
    end
end
