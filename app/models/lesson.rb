class Lesson < ApplicationRecord
  include Typesense
  include MediaHandler
  include Publishable
  include DomainAssignable
  include AudioFallback
  include AttachmentSerializable
  include TranscriptionConcern


  belongs_to :series
  delegate :scholar, to: :series

  validates :title, presence: true

  typesense enqueue: true, if: :published? do
    attribute :title
    attribute :description do
      description || ""
    end
    attribute :content_text do
      description.present? ? description : ""
    end

    attribute :content_type do
      "lesson"
    end
    attribute :slug do
      id.to_s  # Lessons use id for URL, not friendly_id
    end
    attribute :series_title do
      series.title
    end
    attribute :series_slug do
      series.slug
    end
    attribute :series_id
    attribute :position
    attribute :duration do
      duration || 0
    end
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
    # Timestamp fields for sorting (named _ts to avoid overriding model attributes)
    attribute :published_at_ts do
      published_at&.to_i
    end
    attribute :created_at_ts do
      created_at&.to_i
    end

    predefined_fields [
      { "name" => "title", "type" => "string", "locale" => "ar" },
      { "name" => "description", "type" => "string", "locale" => "ar" },
      { "name" => "content_text", "type" => "string", "locale" => "ar" },
      { "name" => "content_type", "type" => "string", "facet" => true },
      { "name" => "slug", "type" => "string" },
      { "name" => "series_title", "type" => "string", "facet" => true },
      { "name" => "series_slug", "type" => "string" },
      { "name" => "series_id", "type" => "int32", "facet" => true },
      { "name" => "position", "type" => "int32" },
      { "name" => "duration", "type" => "int32" },
      { "name" => "scholar_name", "type" => "string", "facet" => true },
      { "name" => "scholar_id", "type" => "int32", "facet" => true },
      { "name" => "media_type", "type" => "string", "facet" => true },
      { "name" => "domain_ids", "type" => "int32[]", "facet" => true },
      { "name" => "published_at_ts", "type" => "int64", "optional" => true },
      { "name" => "created_at_ts", "type" => "int64" }
    ]

    symbols_to_index [ "-", "_" ]
    token_separators [ "-", "_" ]
  end

  has_one_attached :thumbnail, service: Rails.application.config.public_storage
  has_one_attached :audio, service: Rails.application.config.public_storage
  has_one_attached :video, service: Rails.application.config.public_storage
  has_one_attached :optimized_audio, service: Rails.application.config.public_storage
  has_one_attached :final_audio, service: :public_media_aws

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
    # todo fix position nil case I did update some
    # that had no position with the the id but need to fix properly
    "all-audios/#{scholar.full_name}/series/#{series_title}/#{position}.mp3"
  end

  def generate_final_audio_bucket_key
    raise ArgumentError, "Lesson##{id} must have a position to generate final_audio bucket key" if position.blank?

    "all-audios/#{scholar.full_name}/series/#{series_title}/#{position}.mp3"
  end

  def migrate_to_final_audio
    return false unless optimized_audio.attached?
    return true if final_audio.attached? # Skip if already migrated

    begin
      raise ArgumentError, "Lesson##{id} must have a position to migrate" if position.blank?

      # Download the optimized_audio blob
      optimized_audio.open do |tempfile|
        # Get the proper key/path for the new file
        key = generate_final_audio_bucket_key

        # Attach to final_audio with the proper key
        final_audio.attach(
          io: tempfile,
          filename: "#{position}.mp3",
          content_type: "audio/mpeg",
          key: key
        )
      end

      Rails.logger.info "Successfully migrated Lesson##{id} optimized_audio to final_audio"
      true
    rescue => e
      Rails.logger.error "Failed to migrate Lesson##{id}: #{e.message}"
      false
    end
  end

  def scholar
    series.scholar
  end
end
