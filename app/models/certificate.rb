class Certificate < ApplicationRecord
  # Optional: deleting the learner's account deletes the enrollment and the
  # database nullifies this reference, so the number still resolves.
  belongs_to :enrollment, optional: true
  belongs_to :domain

  validates :number, :issued_at, :full_name_snapshot, presence: true
  validates :number, uniqueness: true
  validates :gender_snapshot, inclusion: { in: Learner.genders.keys }

  # The day the learner finished, as the cohort's calendar reads it.
  def issued_on
    issued_at.in_time_zone(enrollment&.cohort&.time_zone || Time.zone).to_date
  end

  def revoked?
    revoked_at.present?
  end

  def to_param
    number
  end
end
