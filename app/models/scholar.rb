class Scholar < ApplicationRecord
  include Publishable
  include Sluggable

  has_many :lectures, dependent: :nullify
  has_many :series, dependent: :nullify
  has_many :benefits, dependent: :nullify
  has_many :articles, dependent: :nullify

  friendly_id :name, use: [ :slugged, :history, :sequentially_slugged ]

  has_many :articles, foreign_key: :author_id, dependent: :restrict_with_error, inverse_of: :author
  has_many :benefits,  dependent: :nullify, inverse_of: :scholar
  has_many :books,     foreign_key: :author_id, dependent: :restrict_with_error, inverse_of: :author
  has_many :lectures,  dependent: :restrict_with_error, inverse_of: :scholar
  has_many :series,    dependent: :restrict_with_error, inverse_of: :scholar
  has_many :fatwas,    dependent: :nullify, inverse_of: :scholar
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

  def as_json(options = {})
    {
      id: id,
      first_name: first_name,
      last_name: last_name,
      full_name: name,
      full_name_alias: full_name_alias
    }
  end

  def normalize_friendly_id(value, sep: "-")
    normalize_for_slug(value, sep:)
  end

  protected

  def should_generate_new_friendly_id?
    will_save_change_to_first_name? || will_save_change_to_last_name? || slug.blank?
  end
end
