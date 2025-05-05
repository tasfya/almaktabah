class BookSerializer < ActiveModel::Serializer
  attributes :id, :created_at, :updated_at

  belongs_to :author, serializer: ScholarSerializer
end
