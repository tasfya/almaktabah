class Track < ApplicationRecord
  enum difficulty_level: { easy: 0, medium: 1, hard: 2 }
  has_many :track_series, dependent: :destroy
  has_many :series, through: :track_series
end
