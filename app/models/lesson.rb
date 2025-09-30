class Lesson < ApplicationRecord
  include Typesense
  include MediaHandler
  include Publishable
  include DomainAssignable
  include AudioFallback
  include AttachmentSerializable


  belongs_to :series
  delegate :scholar, to: :series

  validates :title, presence: true

  typesense enqueue: true, if: :published? do
    attribute :title
    attribute :description
    attribute :content_text do
      description.present? ? description : ""
    end

    attribute :content_type do
      "lesson"
    end
    attribute :series_title do
      series.title
    end
    attribute :series_id
    attribute :position
    attribute :duration
    attribute :scholar_name do
      scholar.name
    end
    attribute :scholar_id do
      scholar.id
    end
    attribute :media_type do
      video.attached? ? "video" : "audio"
    end
    attribute :domain_ids do
      domain_assignments.pluck(:domain_id)
    end

    predefined_fields [
      { "name" => "title", "type" => "string", "locale" => "ar" },
      { "name" => "description", "type" => "string", "locale" => "ar" },
      { "name" => "content_text", "type" => "string", "locale" => "ar" },
      { "name" => "content_type", "type" => "string", "facet" => true },
      { "name" => "series_title", "type" => "string", "facet" => true },
      { "name" => "series_id", "type" => "int32", "facet" => true },
      { "name" => "position", "type" => "int32" },
      { "name" => "duration", "type" => "int32" },
      { "name" => "scholar_name", "type" => "string", "facet" => true },
      { "name" => "scholar_id", "type" => "int32", "facet" => true },
      { "name" => "media_type", "type" => "string", "facet" => true },
      { "name" => "domain_ids", "type" => "int32[]", "facet" => true },
      { "name" => "published_at", "type" => "int64" },
      { "name" => "created_at", "type" => "int64" }
    ]

    default_sorting_field "published_at"

    symbols_to_index [ "-", "_" ]
    token_separators [ "-", "_" ]
  end

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

    attachment_url(audio)
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
end
