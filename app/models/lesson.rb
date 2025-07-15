class Lesson < ApplicationRecord
  include MediaHandler
  include Publishable
  include DomainAssignable

  belongs_to :series

  validates :title, presence: true

  has_one_attached :thumbnail, service: Rails.application.config.public_storage
  has_one_attached :audio, service: Rails.application.config.public_storage
  has_one_attached :video, service: Rails.application.config.public_storage
  has_one_attached :optimized_audio, service: Rails.application.config.public_storage

  has_rich_text :content

  # Scopes
  scope :recent, -> { order(published_at: :desc) }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :by_series, ->(series_id) { where(series_id: series_id) if series_id.present? }

  scope :ordered_by_lesson_number, -> { order(Arel.sql("COALESCE(position, 999999)")) }

  default_scope { ordered_by_lesson_number }

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "category", "created_at", "description", "duration", "id", "published", "published_at", "scholar_id", "series_id", "title", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "series", "scholar" ]
  end

  def media_type
    video? ? I18n.t("common.video") : I18n.t("common.audio")
  end

  def full_title
    "#{series_title} #{title}"
  end

  def audio_url
    return nil unless audio.attached?
    Rails.application.routes.url_helpers.rails_blob_url(audio, only_path: true)
  end

  def series_title
    series.title
  end

  def extract_lesson_number
    match = title.match(/(\d+)/)
    match ? match[1].to_i : Float::INFINITY
  end
end
