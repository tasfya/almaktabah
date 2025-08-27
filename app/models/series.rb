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
end
