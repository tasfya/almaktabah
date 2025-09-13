class Fatwa < ApplicationRecord
  include Sluggable
  include Publishable
  include DomainAssignable
  include MediaHandler
  include AudioFallback
  include AttachmentSerializable

  belongs_to :scholar, optional: true, inverse_of: :fatwas

  has_one_attached :audio, service: Rails.application.config.public_storage
  has_one_attached :optimized_audio, service: Rails.application.config.public_storage

  has_rich_text :question
  has_rich_text :answer

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "category", "description", "created_at", "id", "published", "published_at", "scholar_id", "title", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "scholar" ]
  end
end
