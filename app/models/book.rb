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

  ##
  # Returns a Hash representation of the Book suitable for JSON serialization.
  #
  # Includes basic attributes (id, title, description, category, published_at, downloads),
  # a nested `author` object containing the author's `id` and `name`, and attachment URLs
  # for `file` and `cover_image` when those attachments are present.
  #
  # @param [Hash] options (unused) Optional options hash for compatibility with callers that pass options.
  # @return [Hash] The serializable representation. `file_url` and `cover_image_url` are `nil`
  #   when the corresponding attachment is not present. URLs are generated with `only_path: true`.
  def as_json(options = {})
    {
      id: id,
      title: title,
      description: description,
      category: category,
      published_at: published_at,
      downloads: downloads,
      author: {
        id: author.id,
        name: author.name
      },
      file_url: file.attached? ? Rails.application.routes.url_helpers.rails_blob_url(file, only_path: true) : nil,
      cover_image_url: cover_image.attached? ? Rails.application.routes.url_helpers.rails_blob_url(cover_image, only_path: true) : nil
    }
  end
end
