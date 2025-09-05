class Article < ApplicationRecord
  include Publishable
  include DomainAssignable

  belongs_to :author, class_name: "Scholar"

  has_rich_text :content

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "id", "title", "author_id", "published", "published_at", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "author" ]
  end

  def as_json(options = {})
    {
      id: id,
      title: title,
      content: content&.body&.to_html,
      published_at: published_at,
      author: author.as_json
    }
  end
end
