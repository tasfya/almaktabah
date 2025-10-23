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
    attribute :slug
    attribute :content_text do
      question_text = question.present? ? question.to_plain_text : ""
      answer_text = answer.present? ? answer.to_plain_text : ""
      "#{question_text} #{answer_text}".strip
    end

    attribute :content_type do
      "fatwa"
    end
    attribute :scholar_name do
      scholar&.name
    end
    attribute :scholar_id
    attribute :media_type do
      audio.attached? ? "audio" : "text"
    end
    attribute :domain_ids do
      domain_assignments.pluck(:domain_id)
    end
    attribute :published_at do
      published_at.to_i
    end
    attribute :created_at do
      created_at.to_i
    end

    predefined_fields [
      { "name" => "title", "type" => "string", "locale" => "ar" },
      { "name" => "slug", "type" => "string" },
      { "name" => "content_text", "type" => "string", "locale" => "ar" },
      { "name" => "content_type", "type" => "string", "facet" => true },
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
