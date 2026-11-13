class Exam < ApplicationRecord
  belongs_to :program
  has_many :questions, -> { order(:position) }, dependent: :destroy, inverse_of: :exam
  has_many :program_items, dependent: :restrict_with_error

  validates :title, presence: true
  validate :program_kept_while_used, on: :update

  private

  def program_kept_while_used
    errors.add(:program, :invalid) if program_id_changed? && program_items.exists?
  end
end
