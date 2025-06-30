class Series < ApplicationRecord
    has_many :lessons, dependent: :nullify

    # Scopes
    scope :recent, -> { order(published_date: :desc) }
    scope :by_category, ->(category) { where(category: category) if category.present? }
    scope :with_lessons, -> { joins(:lessons).distinct }

    # Ransack configuration
    def self.ransackable_attributes(auth_object = nil)
        [ "category", "created_at", "description", "id", "published_date", "title", "updated_at" ]
    end

    def self.ransackable_associations(auth_object = nil)
        [ "lessons" ]
    end
end
