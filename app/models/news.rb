require "digest/md5"

class News < ApplicationRecord
  include Sluggable
  include Publishable
  include DomainAssignable
  include AttachmentSerializable

  has_one_attached :thumbnail, service: Rails.application.config.public_storage

  validates :title, presence: true
  validates :content, presence: true
  validates :published_at, presence: true, if: :published?
  validates :slug, presence: true, uniqueness: true

  scope :recent, -> { order(published_at: :desc) }

  has_rich_text :content

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "published_at", "slug", "title", "description", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def as_json(options = {})
    {
      id: id,
      title: title,
      description: description,
      slug: slug,
      published_at: published_at,
      content_excerpt: content.to_plain_text.truncate(200),
      thumbnail_url: attachment_url(thumbnail)
    }
  end

  private

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
