class Exam < ApplicationRecord
  belongs_to :program
  has_many :questions, -> { order(:position) }, dependent: :destroy, inverse_of: :exam
  has_many :program_items, dependent: :restrict_with_error
  has_many :exam_attempts, dependent: :restrict_with_error

  validates :title, presence: true
  before_destroy :keep_while_attempted, prepend: true
  validate :program_kept_while_used, on: :update

  private

  # Runs before the questions cascade, whose own restriction would abort
  # the destroy without an error on the exam.
  def keep_while_attempted
    return unless exam_attempts.exists?

    errors.add(:base, :has_exam_attempts)
    throw :abort
  end

  def program_kept_while_used
    errors.add(:program, :invalid) if program_id_changed? && program_items.exists?
  end
end
