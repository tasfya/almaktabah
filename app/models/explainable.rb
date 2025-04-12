class Explainable < ApplicationRecord
  belongs_to :author
  belongs_to :explainer
  has_rich_text :description
  has_one_attached :pdf_file
end
