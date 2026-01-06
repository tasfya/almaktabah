class Fatwa < ApplicationRecord
  include Typesense
  include Sluggable
  include Publishable
  include DomainAssignable
  include MediaHandler
  include AudioFallback
  include AttachmentSerializable

  belongs_to :scholar, optional: true, inverse_of: :fatwas
  has_one_attached :audio, service: Rails.application.config.public_storage
  has_one_attached :optimized_audio, service: Rails.application.config.public_storage
  has_one_attached :video, service: Rails.application.config.public_storage

  has_rich_text :question
  has_rich_text :answer

  typesense enqueue: true, if: :published? do
    attribute :title
    attribute :content_text do
      question_text = question.present? ? question.to_plain_text : ""
      answer_text = answer.present? ? answer.to_plain_text : ""
      "#{question_text} #{answer_text}".strip
    end

    attribute :content_type do
      "fatwa"
    end
    attribute :slug
    attribute :scholar_name do
      scholar&.name
    end
    attribute :scholar_slug do
      scholar&.slug
    end
    attribute :scholar_id
    attribute :media_type do
      audio.attached? ? "audio" : "text"
    end
    attribute :audio_url do
      attachment_url(optimized_audio.attached? ? optimized_audio : audio)
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
      Rails.application.routes.url_helpers.fatwa_path(self)
    end

    predefined_fields [
      { "name" => "title", "type" => "string", "locale" => "ar" },
      { "name" => "content_text", "type" => "string", "locale" => "ar" },
      { "name" => "content_type", "type" => "string", "facet" => true },
      { "name" => "slug", "type" => "string" },
      { "name" => "scholar_name", "type" => "string", "facet" => true, "optional" => true },
      { "name" => "scholar_slug", "type" => "string", "optional" => true },
      { "name" => "scholar_id", "type" => "int32", "facet" => true, "optional" => true },
      { "name" => "media_type", "type" => "string", "facet" => true },
      { "name" => "audio_url", "type" => "string", "optional" => true },
      { "name" => "domain_ids", "type" => "int32[]", "facet" => true },
      { "name" => "published_at_ts", "type" => "int64", "optional" => true },
      { "name" => "created_at_ts", "type" => "int64" },
      { "name" => "url", "type" => "string" }
    ]

    symbols_to_index [ "-", "_" ]
    token_separators [ "-", "_" ]
  end

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "category", "description", "created_at", "id", "published", "published_at", "scholar_id", "title", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "scholar" ]
  end

  def video?
    video.attached?
  end
end
