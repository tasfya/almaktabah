class Choice < ApplicationRecord
  belongs_to :question, inverse_of: :choices

  validates :body, presence: true
  validates :position, presence: true, uniqueness: { scope: :question_id }
end
