class Book < ApplicationRecord
  include ApplicationHelper
  include Publishable
  include DomainAssignable

  belongs_to :author, class_name: "Scholar", foreign_key: "author_id"
  has_one_attached :file, service: Rails.application.config.public_storage
  has_one_attached :cover_image, service: Rails.application.config.public_storage

  validates :author, presence: true
  validates :title, presence: true, uniqueness: true

  # Scopes
  scope :recent, -> { order(published_at: :desc) }
  scope :most_downloaded, -> { order(downloads: :desc) }
  scope :by_category, ->(category) { where(category: category) if category.present? }

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "author_id", "category", "created_at", "description", "downloads", "id", "published", "published_at", "title", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "author" ]
  end

  def generate_bucket_key(prefix: nil, attachment_name: nil, extension: nil)
    scholar_slug = author&.name ? slugify_arabic(author.name) : "unknown-scholar"
    key = "scholars/#{scholar_slug}/books/#{slugify_arabic(title)}"

    if prefix
      key += "#{prefix}"
    end

    "#{key}#{extension}"
  end
end
