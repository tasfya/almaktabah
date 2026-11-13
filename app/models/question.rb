class Question < ApplicationRecord
  belongs_to :exam, inverse_of: :questions
  has_many :choices, -> { order(:position) }, dependent: :destroy, inverse_of: :question, autosave: true

  enum :kind, { single_choice: 0, true_false: 1 }

  validates :body, :kind, presence: true
  validates :position, presence: true, uniqueness: { scope: :exam_id }
  validate :exactly_one_correct_choice, if: -> { current_choices.any? }
  validate :two_choices_for_true_false, if: -> { true_false? && current_choices.any? }

  def correct_choice
    choices.find(&:correct?)
  end

  private

  def current_choices
    choices.reject(&:marked_for_destruction?)
  end

  def exactly_one_correct_choice
    errors.add(:choices, :exactly_one_correct) unless current_choices.count(&:correct?) == 1
  end

  def two_choices_for_true_false
    errors.add(:choices, :two_for_true_false) unless current_choices.size == 2
  end
end
