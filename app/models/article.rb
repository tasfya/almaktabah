class Article < ApplicationRecord
  belongs_to :author, class_name: "Scholar", foreign_key: "author_id"
end
