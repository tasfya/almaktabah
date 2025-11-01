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
    attribute :description
    attribute :content_text do
      description.present? ? description : ""
    end

    # Faceted filtering fields
    attribute :content_type do
      "book"
    end
    attribute :scholar_name do
      scholar.name
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
    attribute :published_at do
      published_at&.to_i
    end
    attribute :created_at do
      created_at.to_i
    end

    # Predefined fields with Arabic locale
    predefined_fields [
      { "name" => "title", "type" => "string", "locale" => "ar" },
      { "name" => "description", "type" => "string", "locale" => "ar" },
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
