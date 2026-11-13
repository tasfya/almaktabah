class Enrollment < ApplicationRecord
  belongs_to :learner
  belongs_to :cohort
  belongs_to :domain
  has_many :lesson_completions, dependent: :delete_all

  validates :cohort_id, uniqueness: { scope: :learner_id }

  before_validation { self.enrolled_at ||= Time.current }
end
