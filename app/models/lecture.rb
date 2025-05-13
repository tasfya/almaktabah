class Lecture < ApplicationRecord
    has_one_attached :thumbnail
    has_one_attached :audio
end
