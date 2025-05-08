class Fatwa < ApplicationRecord
  has_rich_text :question
  has_rich_text :answer
end
