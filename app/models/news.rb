require "digest/md5"

class News < ApplicationRecord
  include Publishable
  include DomainAssignable

  has_one_attached :thumbnail, service: Rails.application.config.public_storage

  validates :title, presence: true
  validates :content, presence: true
  validates :published_at, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :recent, -> { order(published_at: :desc) }

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  has_rich_text :content

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "published_at", "slug", "title", "description", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  ##
  # Returns a JSON-serializable Hash representation of the News record.
  # Includes: id, title, description, slug, published_at, a 200-character plain-text excerpt of `content`, and `thumbnail_url` (only_path URL when a thumbnail is attached, otherwise `nil`).
  # @param [Hash] options - Optional serialization options (accepted for API compatibility but currently ignored).
  # @return [Hash] The serialized attributes suitable for `to_json`.
  def as_json(options = {})
    {
      id: id,
      title: title,
      description: description,
      slug: slug,
      published_at: published_at,
      content_excerpt: content.to_plain_text.truncate(200),
      thumbnail_url: thumbnail.attached? ? Rails.application.routes.url_helpers.rails_blob_url(thumbnail, only_path: true) : nil
    }
  end

  private

  ##
  # Generates and assigns a URL-safe, unique slug for the record based on its title.
  #
  # The slug is created by trimming whitespace, replacing internal spaces with dashes,
  # and removing characters except Arabic letters, word characters, and dashes.
  # If that produces an empty string, the method falls back to the first eight characters
  # of the MD5 digest of the title.
  #
  # The resulting slug is assigned to `self.slug`. If another News record already uses
  # the same slug, a numeric suffix (`-1`, `-2`, ...) is appended and incremented until
  # a unique slug is found (excluding the current record).
  #
  # This method is intended to be run before validation when `slug` is blank and `title`
  # is present.
  def generate_slug
    base_slug = title.to_s.strip.gsub(/\s+/, "-").gsub(/[^\p{Arabic}\w\-]/, "") # Keep Arabic, Latin, numbers, dashes
    base_slug = base_slug.presence || Digest::MD5.hexdigest(title.to_s)[0..7]   # Fallback if empty

    self.slug = base_slug
    counter = 1

    while News.where(slug: self.slug).where.not(id: self.id).exists?
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
end
