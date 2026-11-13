class ExamAttempt < ApplicationRecord
  belongs_to :enrollment
  belongs_to :exam
  has_many :attempt_answers, dependent: :delete_all

  validates :started_at, presence: true
  validates :exam_id, uniqueness: { scope: :enrollment_id }
  validates :score_percent, numericality: { only_integer: true, in: 0..100 }, allow_nil: true

  def passed?(pass_mark)
    score_percent.present? && score_percent >= pass_mark
  end
end
