class AttemptAnswer < ApplicationRecord
  belongs_to :exam_attempt
  belongs_to :question
  belongs_to :choice

  validates :question_id, uniqueness: { scope: :exam_attempt_id }
end
