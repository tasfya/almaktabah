class Series < ApplicationRecord
    has_many :lessons, dependent: :nullify
end
