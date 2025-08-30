class Lesson < ApplicationRecord
  include MediaHandler
  include Publishable
  include DomainAssignable
  include AudioFallback


  belongs_to :series
  delegate :scholar, to: :series

  validates :title, presence: true

  has_one_attached :thumbnail, service: Rails.application.config.public_storage
  has_one_attached :audio, service: Rails.application.config.public_storage
  has_one_attached :video, service: Rails.application.config.public_storage
  has_one_attached :optimized_audio, service: Rails.application.config.public_storage

  has_rich_text :content

  # Scopes
  scope :recent, -> { order(published_at: :desc) }
  scope :by_series, ->(series_id) { where(series_id: series_id) if series_id.present? }
  scope :with_audio, -> { joins(:audio_attachment) }
  scope :without_audio, -> { where.missing(:audio_attachment) }

  scope :ordered_by_lesson_number, -> { order(Arel.sql("COALESCE(position, 999999)")) }

  default_scope { ordered_by_lesson_number }

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "description", "duration", "id", "published", "published_at", "series_id", "title", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "series" ]
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

  def extract_lesson_number
    match = title.match(/(\d+)/)
    match ? match[1].to_i : Float::INFINITY
  end

  def summary
    description
  end

  def generate_optimize_audio_bucket_key
    key = position? ? position : title
    "all-audios/#{scholar.full_name}/series/#{series_title}/#{key}.mp3"
  end

  def as_json(options = {})
    {
      id: id,
      title: title,
      description: description,
      position: position,
      published_at: published_at,
      duration: duration,
      series: {
        id: series.id,
        title: series.title
      },
      scholar_name: scholar.name,
      thumbnail_url: thumbnail.attached? ? Rails.application.routes.url_helpers.rails_blob_url(thumbnail, only_path: true) : nil,
      audio_url: audio.attached? ? Rails.application.routes.url_helpers.rails_blob_url(audio, only_path: true) : nil,
      video_url: video.attached? ? Rails.application.routes.url_helpers.rails_blob_url(video, only_path: true) : nil
    }
  end
end
