class Article < ApplicationRecord
  include Publishable

  belongs_to :author, class_name: "Scholar"

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "id", "title", "author_id", "published", "published_at", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "author" ]
  end
end
