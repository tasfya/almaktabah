class Scholar < ApplicationRecord
  include Publishable
  include Sluggable
  friendly_id :name, use: [ :slugged, :history ]

  has_rich_text :bio

  # Helper method to get full name
  def name
    "#{first_name} #{last_name}".strip
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "first_name", "id", "last_name", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def normalize_friendly_id(value, sep: "-")
    normalize_for_slug(value, sep:)
  end

  protected

  def should_generate_new_friendly_id?
    will_save_change_to_first_name? || will_save_change_to_last_name? || slug.blank?
  end
end
