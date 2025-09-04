require "digest/md5"

class News < ApplicationRecord
  include Sluggable
  include Publishable
  include DomainAssignable

  has_one_attached :thumbnail, service: Rails.application.config.public_storage

  validates :title, presence: true
  validates :content, presence: true
  validates :published_at, presence: true

  scope :recent, -> { order(published_at: :desc) }

  has_rich_text :content

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "published_at", "slug", "title", "description", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
