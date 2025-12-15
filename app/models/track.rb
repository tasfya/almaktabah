class Track < ApplicationRecord
  enum :difficulty_level, { beginner: 0, intermediate: 1, advanced: 2, expert: 3 }
  has_many :track_series, dependent: :destroy
  has_many :series, through: :track_series
end
