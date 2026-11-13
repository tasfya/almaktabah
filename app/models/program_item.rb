class ProgramItem < ApplicationRecord
  REFERENCES = %i[lesson book exam].freeze

  belongs_to :program, inverse_of: :program_items
  belongs_to :lesson, optional: true
  belongs_to :book, optional: true
  belongs_to :exam, optional: true
  has_many :cohort_slots, dependent: :destroy
  has_many :lesson_completions, dependent: :restrict_with_error

  enum :kind, { lesson: 0, book: 1, exam: 2 }

  validates :kind, presence: true
  validates :position, presence: true, uniqueness: { scope: :program_id }
  validate :reference_matches_kind
  validate :exam_of_same_program

  def display_title
    title_override.presence || (lesson || book || exam)&.title
  end

  private

  def exam_of_same_program
    errors.add(:exam, :invalid) if exam && exam.program_id != program_id
  end

  def reference_matches_kind
    REFERENCES.each do |reference|
      present = public_send(reference).present?
      if reference.to_s == kind
        errors.add(reference, :blank) unless present
      elsif present
        errors.add(:"#{reference}_id", :present)
      end
    end
  end
end
