class Series < ApplicationRecord
    include Typesense
    include Sluggable
    include Publishable
    include DomainAssignable
    include AttachmentSerializable

    has_one_attached :explainable, service: Rails.application.config.public_storage
    has_many :lessons, dependent: :destroy
    belongs_to :scholar, inverse_of: :series

    typesense enqueue: true, if: :published? do
        attribute :title
        attribute :description
        attribute :content_text do
            description.present? ? description : ""
        end

        attribute :content_type do
            "series"
        end
        attribute :slug
        attribute :lesson_count do
            lessons.count
        end
        attribute :scholar_name do
            scholar.name
        end
        attribute :scholar_slug do
            scholar.slug
        end
        attribute :scholar_id
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
        attribute :url do
            Rails.application.routes.url_helpers.series_path(self, scholar_id: scholar.slug)
        end

        predefined_fields [
            { "name" => "title", "type" => "string", "locale" => "ar" },
            { "name" => "description", "type" => "string", "locale" => "ar" },
            { "name" => "content_text", "type" => "string", "locale" => "ar" },
            { "name" => "content_type", "type" => "string", "facet" => true },
            { "name" => "slug", "type" => "string" },
            { "name" => "lesson_count", "type" => "int32" },
            { "name" => "scholar_name", "type" => "string", "facet" => true },
            { "name" => "scholar_slug", "type" => "string" },
            { "name" => "scholar_id", "type" => "int32", "facet" => true },
            { "name" => "media_type", "type" => "string", "facet" => true },
            { "name" => "domain_ids", "type" => "int32[]", "facet" => true },
            { "name" => "published_at_ts", "type" => "int64" },
            { "name" => "created_at_ts", "type" => "int64" },
            { "name" => "url", "type" => "string" }
        ]

        default_sorting_field "published_at_ts"

        symbols_to_index [ "-", "_" ]
        token_separators [ "-", "_" ]
    end

    # Scopes
    scope :recent, -> { order(published_at: :desc) }
    scope :by_category, ->(category) { where(category: category) if category.present? }
    scope :with_lessons, -> { joins(:lessons).distinct }

    # Ransack configuration
    def self.ransackable_attributes(auth_object = nil)
        [ "category", "created_at", "description", "id", "published", "published_at", "scholar_id", "title", "updated_at" ]
    end

    def self.ransackable_associations(auth_object = nil)
      [ "lessons", "scholar" ]
    end

    def seo_show_title
      "#{title} - #{scholar.full_name}"
    end
end
