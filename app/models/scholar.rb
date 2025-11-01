class Scholar < ApplicationRecord
  include Typesense
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

  typesense enqueue: true, if: :published? do
    attribute :name
    attribute :first_name
    attribute :last_name
    attribute :content_text do
      bio.present? ? bio.to_plain_text : ""
    end

    attribute :content_type do
      "scholar"
    end
    attribute :books_count do
      books.count
    end
    attribute :lectures_count do
      lectures.count
    end
    attribute :series_count do
      series.count
    end
    attribute :fatwas_count do
      fatwas.count
    end
    attribute :media_type do
      "text"
    end
    attribute :published_at do
      published_at&.to_i
    end
    attribute :created_at do
      created_at.to_i
    end

    predefined_fields [
      { "name" => "name", "type" => "string", "locale" => "ar", "facet" => true },
      { "name" => "first_name", "type" => "string", "locale" => "ar" },
      { "name" => "last_name", "type" => "string", "locale" => "ar" },
      { "name" => "content_text", "type" => "string", "locale" => "ar" },
      { "name" => "content_type", "type" => "string", "facet" => true },
      { "name" => "books_count", "type" => "int32" },
      { "name" => "lectures_count", "type" => "int32" },
      { "name" => "series_count", "type" => "int32" },
      { "name" => "fatwas_count", "type" => "int32" },
      { "name" => "media_type", "type" => "string", "facet" => true },
      { "name" => "published_at", "type" => "int64" },
      { "name" => "created_at", "type" => "int64" }
    ]

    default_sorting_field "published_at"

    symbols_to_index [ "-", "_" ]
    token_separators [ "-", "_" ]
  end

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
