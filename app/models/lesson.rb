class Lesson < ApplicationRecord
    belongs_to :series
    validates :title, presence: true
    validates :published_date, presence: true
    validates :category, presence: true
    validates :duration, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

    has_one_attached :audio, service: Rails.application.config.public_storage
    has_one_attached :thumbnail, service: Rails.application.config.public_storage
    has_rich_text :content

    # Returns the series title if the lesson belongs to a series
    def series_title
      series&.title
    end
end
