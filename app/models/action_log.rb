class ActionLog < ApplicationRecord
  belongs_to :actionable, polymorphic: true
end
