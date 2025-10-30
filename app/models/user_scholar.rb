# frozen_string_literal: true

class UserScholar < ApplicationRecord
  belongs_to :user
  belongs_to :scholar
end
