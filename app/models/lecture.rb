class Lecture < ApplicationRecord
  include MediaHandler
  include DomainAssignable
  include Publishable

  validates :title, presence: true

  has_one_attached :thumbnail, service: Rails.application.config.public_storage
  has_one_attached :audio, service: Rails.application.config.public_storage
  has_one_attached :video, service: Rails.application.config.public_storage
  has_one_attached :optimized_audio, service: Rails.application.config.public_storage
  has_rich_text :content
  belongs_to :scholar

  scope :recent, -> { order(published_at: :desc) }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  def self.ransackable_attributes(auth_object = nil)
    [ "category", "created_at", "description", "duration", "id", "published", "published_at", "scholar_id", "title", "updated_at" ]
  end
  scope :with_audio, -> { joins(:audio_attachment) }
  scope :without_audio, -> { where.missing(:audio_attachment) }

  def self.ransackable_associations(auth_object = nil)
    [ "scholar" ]
  end

  def podcast_title
    title
  end
  def audio_file_size
    return nil unless audio.attached?

    audio.blob.byte_size
  end

  def summary
    description
  end

  def audio_url
    return nil unless audio.attached?

    Rails.application.routes.url_helpers.rails_blob_url(audio, only_path: true)
  end
end
