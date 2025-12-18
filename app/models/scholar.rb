class Scholar < ApplicationRecord
  include Publishable
  include Sluggable

  has_many :user_scholars, dependent: :destroy
  has_many :users, through: :user_scholars
  has_many :articles, foreign_key: :author_id, dependent: :restrict_with_error
  has_many :books, foreign_key: :author_id, dependent: :restrict_with_error
  has_many :lectures, dependent: :restrict_with_error
  has_many :series, dependent: :restrict_with_error
  has_many :fatwas, dependent: :restrict_with_error
  belongs_to :default_domain, class_name: "Domain", optional: true
  has_rich_text :bio

  friendly_id :name, use: [ :slugged, :history, :sequentially_slugged ]

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
