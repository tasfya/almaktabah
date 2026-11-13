class LessonCompletion < ApplicationRecord
  belongs_to :enrollment
  belongs_to :program_item

  validates :completed_at, presence: true
  validates :program_item_id, uniqueness: { scope: :enrollment_id }
end
