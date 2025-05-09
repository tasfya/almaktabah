class Lesson < ApplicationRecord
    validates :title, presence: true
    validates :published_date, presence: true
    validates :category, presence: true
    validates :duration, presence: true, numericality: { only_integer: true, greater_than: 0 }

    has_one_attached :audio
    has_one_attached :thumbnail
    has_rich_text :content

    validates :audio, presence: true
    validates :thumbnail, presence: true
end
