class Cohort < ApplicationRecord
  belongs_to :program
  has_many :cohort_slots, dependent: :delete_all, inverse_of: :cohort

  validates :name, :starts_on, presence: true
  validate :known_time_zone

  before_save :default_enrollment_closes_at

  def today
    Time.current.in_time_zone(time_zone).to_date
  end

  def lesson_slots
    slots_of_kind(:lesson)
  end

  def exam_slots
    slots_of_kind(:exam)
  end

  def enrollment_open?(at = Time.current)
    enrollment_closes_at.nil? || at < enrollment_closes_at
  end

  private

  def slots_of_kind(kind)
    cohort_slots.joins(:program_item).merge(ProgramItem.where(kind: kind).order(:position))
  end

  def default_enrollment_closes_at
    self.enrollment_closes_at ||= exam_slots.minimum(:closes_at) if persisted?
  end

  def known_time_zone
    errors.add(:time_zone, :inclusion) unless ActiveSupport::TimeZone[time_zone.to_s]
  end
end
