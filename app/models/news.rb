class News < ApplicationRecord
  include Typesense
  include Sluggable
  include Publishable
  include DomainAssignable
  include AttachmentSerializable

  has_one_attached :thumbnail, service: Rails.application.config.public_storage do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
  end

  validates :title, presence: true
  validates :content, presence: true
  validates :published_at, presence: true, if: :published?
  validates :slug, presence: true, uniqueness: true

  typesense enqueue: true, if: :published? do
    attribute :title
    attribute :slug
    attribute :description
    attribute :content_text do
      content.present? ? content.to_plain_text : ""
    end

    attribute :content_type do
      "news"
    end
    attribute :scholar_name do
      ""
    end
    attribute :media_type do
      "text"
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
    attribute :thumbnail_url do
      thumbnail.attached? ? variant_url(thumbnail.variant(:thumb)) : nil
    end

    predefined_fields [
      { "name" => "title", "type" => "string", "locale" => "ar" },
      { "name" => "slug", "type" => "string" },
      { "name" => "description", "type" => "string", "locale" => "ar" },
      { "name" => "content_text", "type" => "string", "locale" => "ar" },
      { "name" => "content_type", "type" => "string", "facet" => true },
      { "name" => "scholar_name", "type" => "string", "facet" => true },
      { "name" => "media_type", "type" => "string", "facet" => true },
      { "name" => "domain_ids", "type" => "int32[]", "facet" => true },
      { "name" => "published_at", "type" => "int64" },
      { "name" => "created_at", "type" => "int64" },
      { "name" => "thumbnail_url", "type" => "string" }
    ]

    default_sorting_field "published_at"

    symbols_to_index [ "-", "_" ]
    token_separators [ "-", "_" ]
  end

  scope :recent, -> { order(published_at: :desc) }

  has_rich_text :content

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "published_at", "slug", "title", "description", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
