class Series < ApplicationRecord
    include Publishable
    include DomainAssignable

    has_one_attached :explainable, service: Rails.application.config.public_storage
    has_many :lessons, dependent: :destroy
    belongs_to :scholar
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

    ##
    # Returns a compact JSON-ready hash representation of the Series.
    # Includes core attributes, nested scholar info when present, a relative URL for the attached `explainable` blob (or nil), and a count of associated lessons.
    # @param [Hash] options - Unused; accepted for compatibility with ActiveModel#as_json.
    # @return [Hash] A hash with keys :id, :title, :description, :category, :published, :published_at, :scholar, :explainable_url, and :lessons_count.
    def as_json(options = {})
      {
        id: id,
        title: title,
        description: description,
        category: category,
        published: published,
        published_at: published_at,
        scholar: scholar.present? ? { id: scholar.id, name: scholar.name } : nil,
        explainable_url: explainable.attached? ? Rails.application.routes.url_helpers.rails_blob_url(explainable, only_path: true) : nil,
        lessons_count: lessons.count
      }
    end
end
