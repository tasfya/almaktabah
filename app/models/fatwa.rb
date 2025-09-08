class Fatwa < ApplicationRecord
  include Sluggable
  include Publishable
  include DomainAssignable

  has_rich_text :question
  has_rich_text :answer

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "category", "description", "created_at", "id", "published", "published_at", "scholar_id", "title", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "scholar" ]
  end
end
