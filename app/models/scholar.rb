class Scholar < ApplicationRecord
  include Publishable

  has_rich_text :bio

  # Helper method to get full name
  def name
    "#{first_name} #{last_name}".strip
  end

  # Alias for search results consistency
  alias_method :title, :name

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "first_name", "id", "last_name", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
