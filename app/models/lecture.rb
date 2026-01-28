class Lecture < ApplicationRecord
  include Typesense
  include Sluggable
  include MediaHandler
  include DomainAssignable
  include Publishable
  include AudioFallback
  include AttachmentSerializable
  include TranscriptionConcern

  enum :kind, { sermon: 1, conference: 2, benefit: 3 }

  validates :title, presence: true
  validates :source_url, uniqueness: true, allow_blank: true

  typesense enqueue: true, if: :published? do
    attribute :title
    attribute :description do
      description || ""
    end
    attribute :content_text do
      description.present? ? description : ""
    end

    attribute :content_type do
      "lecture"
    end
    attribute :slug
    attribute :kind
    attribute :duration do
      duration || 0
    end
    attribute :scholar_name do
      scholar.name
    end
    attribute :scholar_slug do
      scholar.slug
    end
    attribute :scholar_id
    attribute :media_type do
      video.attached? ? "video" : "audio"
    end
    attribute :audio_url do
      attachment_url(optimized_audio.attached? ? optimized_audio : audio)
    end
    attribute :video_url do
      attachment_url(video)
    end
    attribute :thumbnail_url do
      attachment_url(thumbnail)
    end
    attribute :domain_ids do
      domain_assignments.pluck(:domain_id)
    end
    attribute :published_at_ts do
      published_at&.to_i
    end
    attribute :created_at_ts do
      created_at&.to_i
    end
    attribute :url do
      Rails.application.routes.url_helpers.lecture_path(self, scholar_id: scholar.slug, kind: kind_for_url)
    end

    predefined_fields [
      { "name" => "title", "type" => "string", "locale" => "ar" },
      { "name" => "description", "type" => "string", "locale" => "ar" },
      { "name" => "content_text", "type" => "string", "locale" => "ar" },
      { "name" => "content_type", "type" => "string", "facet" => true },
      { "name" => "slug", "type" => "string" },
      { "name" => "kind", "type" => "string", "facet" => true },
      { "name" => "duration", "type" => "int32" },
      { "name" => "scholar_name", "type" => "string", "facet" => true },
      { "name" => "scholar_slug", "type" => "string" },
      { "name" => "scholar_id", "type" => "int32", "facet" => true },
      { "name" => "media_type", "type" => "string", "facet" => true },
      { "name" => "audio_url", "type" => "string", "optional" => true },
      { "name" => "video_url", "type" => "string", "optional" => true },
      { "name" => "thumbnail_url", "type" => "string", "optional" => true },
      { "name" => "domain_ids", "type" => "int32[]", "facet" => true },
      { "name" => "published_at_ts", "type" => "int64", "optional" => true },
      { "name" => "created_at_ts", "type" => "int64" },
      { "name" => "url", "type" => "string" }
    ]

    symbols_to_index [ "-", "_" ]
    token_separators [ "-", "_" ]
  end

  has_one_attached :thumbnail, service: Rails.application.config.public_storage
  has_one_attached :audio, service: Rails.application.config.public_storage
  has_one_attached :video, service: Rails.application.config.public_storage
  has_one_attached :optimized_audio, service: Rails.application.config.public_storage
  has_one_attached :final_audio, service: Rails.application.config.public_storage

  has_rich_text :content
  belongs_to :scholar, inverse_of: :lectures

  scope :recent, -> { order(published_at: :desc) }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :with_audio, -> { joins(:audio_attachment) }
  scope :without_audio, -> { where.missing(:audio_attachment) }


  def self.ransackable_attributes(auth_object = nil)
    [ "category", "created_at", "description", "duration", "id", "published", "published_at", "scholar_id", "title", "updated_at" ]
  end

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

    # Use direct storage URL for Hetzner public media, fallback to Rails blob URL otherwise
    attachment_url(audio)
  end

  def generate_optimize_audio_bucket_key
    kind ||= "other"
    "all-audios/#{scholar.name}/lectures/#{kind}/#{title}.mp3"
  end

  def kind_for_url
    I18n.t("activerecord.attributes.lecture.kind.#{kind}")
  end

  def seo_show_title
    "#{kind_for_url} - #{title} - #{scholar.full_name}"
  end
end
