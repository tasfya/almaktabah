class ScholarSerializer < ActiveModel::Serializer
  attributes :id, :name, :biography, :created_at, :updated_at

  has_many :books
  has_many :articles
end
