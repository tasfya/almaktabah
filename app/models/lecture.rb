class Lecture < ApplicationRecord
  include Typesense
  include Sluggable
  include MediaHandler
  include DomainAssignable
  include Publishable
  include AudioFallback
  include AttachmentSerializable

  enum :kind, { sermon: 1, conference: 2, benefit: 3 }

  validates :title, presence: true
  validates :source_url, uniqueness: true, allow_blank: true

  typesense enqueue: true, if: :published? do
    attribute :title
    attribute :description
    attribute :content_text do
      description.present? ? description : ""
    end

    attribute :content_type do
      "lecture"
    end
    attribute :kind
    attribute :duration
    attribute :scholar_name do
      scholar.name
    end
    attribute :scholar_id
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
      { "name" => "kind", "type" => "string", "facet" => true },
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
    "all-audios/#{scholar.name}/lectures/#{kind}/#{title}.mp3"
  end

  def kind_translated
    I18n.t("activerecord.attributes.lecture.kind.#{kind}")
  end

  def seo_show_title
    "#{kind_translated} - #{title} - #{scholar.full_name}"
  end
end
