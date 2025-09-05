class Book < ApplicationRecord
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

  def as_json(options = {})
    {
      id: id,
      title: title,
      description: description,
      category: category,
      published_at: published_at,
      downloads: downloads,
      author: author.as_json,
      file_url: file.attached? ? Rails.application.routes.url_helpers.rails_blob_url(file, only_path: true) : nil,
      cover_image_url: cover_image.attached? ? Rails.application.routes.url_helpers.rails_blob_url(cover_image, only_path: true) : nil
    }
  end
end
