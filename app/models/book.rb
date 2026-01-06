class Book < ApplicationRecord
  include Typesense
  include Sluggable
  include Publishable
  include DomainAssignable
  include AttachmentSerializable

  belongs_to :scholar, class_name: "Scholar", foreign_key: "author_id", inverse_of: :books
  has_one_attached :file, service: Rails.application.config.public_storage
  has_one_attached :cover_image, service: Rails.application.config.public_storage

  validates :scholar, presence: true
  validates :title, presence: true, uniqueness: true

  typesense enqueue: true, if: :published? do
    attribute :title
    attribute :description do
      description || ""
    end
    attribute :content_text do
      description.present? ? description : ""
    end

    # Faceted filtering fields
    attribute :content_type do
      "book"
    end
    attribute :slug
    attribute :scholar_name do
      scholar.name
    end
    attribute :scholar_slug do
      scholar.slug
    end
    attribute :scholar_id do
      author_id
    end
    attribute :media_type do
      "text"
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
    attribute :thumbnail_url do
      attachment_url(cover_image)
    end
    attribute :url do
      Rails.application.routes.url_helpers.book_path(self, scholar_id: scholar.slug)
    end

    # Predefined fields with Arabic locale
    predefined_fields [
      { "name" => "title", "type" => "string", "locale" => "ar" },
      { "name" => "description", "type" => "string", "locale" => "ar" },
      { "name" => "content_text", "type" => "string", "locale" => "ar" },
      { "name" => "content_type", "type" => "string", "facet" => true },
      { "name" => "slug", "type" => "string" },
      { "name" => "scholar_name", "type" => "string", "facet" => true },
      { "name" => "scholar_slug", "type" => "string" },
      { "name" => "scholar_id", "type" => "int32", "facet" => true },
      { "name" => "media_type", "type" => "string", "facet" => true },
      { "name" => "domain_ids", "type" => "int32[]", "facet" => true },
      { "name" => "published_at_ts", "type" => "int64", "optional" => true },
      { "name" => "created_at_ts", "type" => "int64" },
      { "name" => "thumbnail_url", "type" => "string", "optional" => true },
      { "name" => "url", "type" => "string" }
    ]

    # Arabic language optimizations
    symbols_to_index [ "-", "_" ]
    token_separators [ "-", "_" ]
  end

  # Scopes
  scope :recent, -> { order(published_at: :desc) }
  scope :most_downloaded, -> { order(downloads: :desc) }
  scope :by_category, ->(category) { where(category: category) if category.present? }

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "author_id", "category", "created_at", "description", "downloads", "id", "published", "published_at", "title", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "scholar" ]
  end
end
