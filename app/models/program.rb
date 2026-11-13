class Program < ApplicationRecord
  include Sluggable
  include Publishable
  include DomainAssignable

  has_many :cohorts, dependent: :destroy
  has_many :program_items, -> { order(:position) }, dependent: :destroy, inverse_of: :program
  has_many :exams, dependent: :destroy

  validates :title, presence: true
  before_destroy :keep_while_enrolled, prepend: true
  validates :pass_mark, numericality: { only_integer: true, in: 0..100 }

  def scholars
    Scholar.where(id: Series.where(id: Lesson.where(id: program_items.lesson.select(:lesson_id)).select(:series_id)).select(:scholar_id))
  end

  private

  # Runs before the cohorts cascade, whose own restriction would abort the
  # destroy without an error on the program.
  def keep_while_enrolled
    return unless Enrollment.joins(:cohort).where(cohorts: { program_id: id }).exists?

    errors.add(:base, :has_enrollments)
    throw :abort
  end
end
