class Benefit < ApplicationRecord
  include Publishable
  include MediaHandler
  include DomainAssignable

  belongs_to :scholar, optional: true
  has_rich_text :content

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 1000 }

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "title", "description", "category", "published", "published_at", "scholar_id", "updated_at", "created_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "scholar" ]
  end
end
