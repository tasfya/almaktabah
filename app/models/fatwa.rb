class Fatwa < ApplicationRecord
  has_rich_text :question
  has_rich_text :answer

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "category", "created_at", "id", "title", "updated_at", "views" ]
  end
end
