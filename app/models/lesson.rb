class Lesson < ApplicationRecord
  include MediaHandler
  include Publishable
  include DomainAssignable
  include ArabicSluggable


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
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :by_series, ->(series_id) { where(series_id: series_id) if series_id.present? }
  scope :with_audio, -> { joins(:audio_attachment) }
  scope :without_audio, -> { where.missing(:audio_attachment) }

  scope :ordered_by_lesson_number, -> { order(Arel.sql("COALESCE(position, 999999)")) }

  default_scope { ordered_by_lesson_number }

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "category", "created_at", "description", "duration", "id", "published", "published_at", "series_id", "title", "updated_at" ]
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

  def generate_bucket_key(prefix: nil)
    series_slug = slugify_arabic_advanced(series.title)
    scholar_slug = slugify_arabic_advanced(series.scholar.name)

    ext = audio.attachment.blob.filename.extension
    name = position ? position.to_s : slugify_arabic_advanced(title)

    base_key = if prefix
      "scholars/#{scholar_slug}/series/#{series_slug}/#{name}#{prefix}.#{ext}"
    else
      "scholars/#{scholar_slug}/series/#{series_slug}/#{name}.#{ext}"
    end

    ensure_unique_key(base_key)
  end

  private

  def ensure_unique_key(key)
    return key unless ActiveStorage::Blob.exists?(key: key)

    counter = 1
    loop do
      name_part, dot, extension = key.rpartition(".")
      new_key = "#{name_part}_#{counter}.#{extension}"
      return new_key unless ActiveStorage::Blob.exists?(key: new_key)
      counter += 1
    end
  end
end
