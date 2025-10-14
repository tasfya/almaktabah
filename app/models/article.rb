class Article < ApplicationRecord
  include Publishable
  include DomainAssignable

  belongs_to :scholar, class_name: "Scholar", foreign_key: "author_id", inverse_of: :articles

  has_rich_text :content

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "id", "title", "author_id", "published", "published_at", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "scholar" ]
  end
end
