class CohortSlot < ApplicationRecord
  belongs_to :cohort, inverse_of: :cohort_slots
  belongs_to :program_item

  validates :available_on, presence: true
  validates :program_item_id, uniqueness: { scope: :cohort_id }
  validates :opens_at, :closes_at, presence: true, if: -> { program_item&.exam? }
  validate :closes_after_opening
  validate :item_of_cohort_program

  def open?(at = Time.current)
    opens_at.present? && closes_at.present? && opens_at <= at && at < closes_at
  end

  def closed?(at = Time.current)
    closes_at.present? && at >= closes_at
  end

  private

  def closes_after_opening
    return if opens_at.blank? || closes_at.blank?

    errors.add(:closes_at, :greater_than, count: opens_at) unless closes_at > opens_at
  end

  def item_of_cohort_program
    return if cohort.blank? || program_item.blank?

    errors.add(:program_item, :invalid) unless program_item.program_id == cohort.program_id
  end
end
