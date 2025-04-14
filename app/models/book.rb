class Book < ApplicationRecord
  belongs_to :author, class_name: "Scholar", foreign_key: "author_id"
  has_one_attached :file, service: :public_media_hetzner

  validates :author, presence: true
end
