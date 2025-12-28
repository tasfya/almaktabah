class Article < ApplicationRecord
  include Typesense
  include Sluggable
  include Publishable
  include DomainAssignable

  belongs_to :scholar, class_name: "Scholar", foreign_key: "author_id", inverse_of: :articles

  has_rich_text :content

  validates :title, presence: true

  typesense enqueue: true, if: :published? do
    attribute :title
    attribute :content_text do
      content.present? ? content.to_plain_text : ""
    end

    attribute :content_type do
      "article"
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
    attribute :read_time do
      read_time_minutes
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
      Rails.application.routes.url_helpers.article_path(self, scholar_id: scholar.slug)
    end

    predefined_fields [
      { "name" => "title", "type" => "string", "locale" => "ar" },
      { "name" => "content_text", "type" => "string", "locale" => "ar" },
      { "name" => "content_type", "type" => "string", "facet" => true },
      { "name" => "slug", "type" => "string" },
      { "name" => "scholar_name", "type" => "string", "facet" => true },
      { "name" => "scholar_slug", "type" => "string" },
      { "name" => "scholar_id", "type" => "int32", "facet" => true },
      { "name" => "media_type", "type" => "string", "facet" => true },
      { "name" => "read_time", "type" => "int32" },
      { "name" => "domain_ids", "type" => "int32[]", "facet" => true },
      { "name" => "published_at_ts", "type" => "int64" },
      { "name" => "created_at_ts", "type" => "int64" },
      { "name" => "url", "type" => "string" }
    ]

    default_sorting_field "published_at_ts"

    symbols_to_index [ "-", "_" ]
    token_separators [ "-", "_" ]
  end

  scope :recent, -> { order(published_at: :desc) }

  def read_time_minutes
    return 0 unless content.present?
    words = content.to_plain_text.split.size
    (words / 200.0).ceil
  end

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "id", "title", "description", "slug", "author_id", "published", "published_at", "created_at", "updated_at" ]
  end

  # Virtual attribute for filter compatibility
  def description
    nil
  end

  def self.ransackable_associations(auth_object = nil)
    [ "scholar" ]
  end
end
