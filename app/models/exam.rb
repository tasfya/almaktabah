class Exam < ApplicationRecord
  belongs_to :program
  has_many :questions, -> { order(:position) }, dependent: :destroy, inverse_of: :exam
  has_many :program_items, dependent: :destroy

  validates :title, presence: true
end
