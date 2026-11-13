class Choice < ApplicationRecord
  belongs_to :question, inverse_of: :choices
  has_many :attempt_answers, dependent: :restrict_with_error

  validates :body, presence: true
  validates :position, presence: true, uniqueness: { scope: :question_id }
  validate :keeps_question_valid, if: :question

  private

  # The question checks its choices when saved with them; this covers a
  # choice saved on its own. Choices loaded on the question (nested forms)
  # are compared in memory, so switching the correct answer in one save works.
  def keeps_question_valid
    others = siblings
    errors.add(:correct, :exactly_one_correct) if correct? && others.any?(&:correct?)
    errors.add(:base, :two_for_true_false) if question.true_false? && others.size >= 2
  end

  def siblings
    if question.choices.loaded?
      question.choices.reject { |choice| choice.equal?(self) || choice.marked_for_destruction? }
    else
      question.choices.where.not(id: id).to_a
    end
  end
end
