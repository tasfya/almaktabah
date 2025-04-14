class Book < ApplicationRecord
  belongs_to :author, class_name: "Scholar", foreign_key: "author_id"
  has_one_attached :file, service: Rails.application.config.public_storage

  validates :author, presence: true
end
