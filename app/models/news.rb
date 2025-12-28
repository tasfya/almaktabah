class News < ApplicationRecord
  include Typesense
  include Sluggable
  include Publishable
  include DomainAssignable
  include AttachmentSerializable

  has_one_attached :thumbnail, service: Rails.application.config.public_storage
  belongs_to :scholar, optional: true
  validates :title, presence: true
  validates :content, presence: true
  validates :published_at, presence: true, if: :published?
  validates :slug, presence: true, uniqueness: true

  typesense enqueue: true, if: :published? do
    attribute :title
    attribute :description
    attribute :content_text do
      content.present? ? content.to_plain_text : ""
    end

    attribute :content_type do
      "news"
    end
    attribute :slug
    attribute :scholar_name do
      scholar&.name
    end
    attribute :scholar_slug do
      scholar&.slug
    end
    attribute :scholar_id do
      scholar_id
    end
    attribute :media_type do
      "text"
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
    attribute :thumbnail_url do
      attachment_url(thumbnail)
    end
    attribute :url do
      Rails.application.routes.url_helpers.news_path(self)
    end

    predefined_fields [
      { "name" => "title", "type" => "string", "locale" => "ar" },
      { "name" => "description", "type" => "string", "locale" => "ar" },
      { "name" => "content_text", "type" => "string", "locale" => "ar" },
      { "name" => "content_type", "type" => "string", "facet" => true },
      { "name" => "slug", "type" => "string" },
      { "name" => "scholar_name", "type" => "string", "facet" => true, "optional" => true },
      { "name" => "scholar_slug", "type" => "string", "optional" => true },
      { "name" => "scholar_id", "type" => "int32", "facet" => true, "optional" => true },
      { "name" => "media_type", "type" => "string", "facet" => true },
      { "name" => "domain_ids", "type" => "int32[]", "facet" => true },
      { "name" => "published_at_ts", "type" => "int64" },
      { "name" => "created_at_ts", "type" => "int64" },
      { "name" => "thumbnail_url", "type" => "string", "optional" => true },
      { "name" => "url", "type" => "string" }
    ]

    default_sorting_field "published_at_ts"

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
