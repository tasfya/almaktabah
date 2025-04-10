class Scholar < ApplicationRecord
  has_many :books, dependent: :destroy
  has_many :articles, dependent: :destroy
end
