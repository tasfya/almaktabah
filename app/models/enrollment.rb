class Enrollment < ApplicationRecord
  belongs_to :learner
  belongs_to :cohort
  belongs_to :domain
  has_many :lesson_completions, dependent: :delete_all
  has_many :exam_attempts, dependent: :destroy
  has_one :certificate # rubocop:disable Rails/HasManyOrHasOneDependent -- the database nullifies it

  validates :cohort_id, uniqueness: { scope: :learner_id }

  before_validation { self.enrolled_at ||= Time.current }
  # The number stays verifiable after the enrollment (or the learner's whole
  # account) is deleted, and must then read as revoked.
  before_destroy { Certificate.where(enrollment_id: id, revoked_at: nil).update_all(revoked_at: Time.current) }
end
