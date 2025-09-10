class Fatwa < ApplicationRecord
  include Sluggable
  include Publishable
  include DomainAssignable

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

  def as_json(options = {})
    {
      id: id,
      title: title,
      question: question&.body&.to_plain_text,
      answer: answer&.body&.to_plain_text,
      category: category,
      published_at: published_at,
      scholar: scholar.present? ? scholar.as_json : nil
    }
  end
end
