class Book < ApplicationRecord
  belongs_to :author, class_name: "Scholar", foreign_key: "author_id"
  has_one_attached :file

  validates :author, presence: true
end
