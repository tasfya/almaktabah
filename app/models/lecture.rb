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
    scope :by_category, ->(category) { where(category: category) if category.present? }

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "category", "created_at", "description", "duration", "id", "published_date", "title", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  after_save :extract_media_duration
  after_commit :process_media_files, on: [ :create, :update ]

  attr_accessor :audio_blob_id_before_save, :video_blob_id_before_save

  before_save :cache_blob_ids

  def video?
    video.attached?
  end

  def audio?
    audio.attached?
  end

  def audio_url
    return nil unless audio.attached?
    Rails.application.routes.url_helpers.rails_blob_url(audio, only_path: true)
  end
end
