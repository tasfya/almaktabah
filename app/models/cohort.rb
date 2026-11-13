class Cohort < ApplicationRecord
  belongs_to :program
  attr_readonly :program_id
  has_many :cohort_slots, dependent: :delete_all, inverse_of: :cohort
  has_many :enrollments, dependent: :restrict_with_error

  validates :name, :starts_on, presence: true
  validate :known_time_zone
  validate :time_zone_kept_while_scheduled, on: :update

  def today(at = Time.current)
    at.in_time_zone(time_zone).to_date
  end

  def lesson_slots
    slots_of_kind(:lesson)
  end

  def exam_slots
    slots_of_kind(:exam)
  end

  # enrollment_closes_at is an admin override; by default enrollment closes
  # with the first exam window, and a cohort without exams stays open.
  def enrollment_deadline
    enrollment_closes_at || exam_slots.minimum(:closes_at)
  end

  def enrollment_open?(at = Time.current)
    deadline = enrollment_deadline
    deadline.nil? || at < deadline
  end

  private

  def slots_of_kind(kind)
    cohort_slots.joins(:program_item).merge(ProgramItem.where(kind: kind).order(:position))
  end

  # Lesson dates are read in the cohort's zone while exam windows are stored
  # instants, so a new zone would move one and not the other. Regenerate the
  # schedule instead.
  def time_zone_kept_while_scheduled
    errors.add(:time_zone, :kept_while_scheduled) if will_save_change_to_time_zone? && cohort_slots.exists?
  end

  def known_time_zone
    errors.add(:time_zone, :inclusion) unless ActiveSupport::TimeZone[time_zone.to_s]
  end
end
