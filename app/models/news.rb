require "digest/md5"

class News < ApplicationRecord
  has_one_attached :thumbnail, service: Rails.application.config.public_storage

  validates :title, presence: true
  validates :content, presence: true
  validates :published_at, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :recent, -> { order(published_at: :desc) }

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  has_rich_text :content

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
