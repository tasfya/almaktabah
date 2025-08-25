class Lesson < ApplicationRecord
  include MediaHandler
  include Publishable
  include DomainAssignable

  belongs_to :series
  validates :title, presence: true
  has_rich_text :content

  # Scopes
  scope :recent, -> { order(published_at: :desc) }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :by_series, ->(series_id) { where(series_id: series_id) if series_id.present? }
  scope :with_audio, -> { joins(:audio_attachment) }
  scope :without_audio, -> { where.missing(:audio_attachment) }

  scope :ordered_by_lesson_number, -> { order(Arel.sql("COALESCE(position, 999999)")) }

  default_scope { ordered_by_lesson_number }

  delegate :scholar, to: :series

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

  def audio_file_size
    return nil unless audio.attached?

    audio.blob.byte_size
  end

  def podcast_title
    "#{position} - #{series.title} - #{title}"
  end

  def series_title
    series.title
  end

  def summary
    description
  end
end
