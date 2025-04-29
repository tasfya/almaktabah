class BookSerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :created_at, :updated_at

  belongs_to :scholar, serializer: ScholarSerializer
end
