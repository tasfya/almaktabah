class Lecture < ApplicationRecord
    has_one_attached :thumbnail
    has_one_attached :audio
    has_rich_text :content
end
