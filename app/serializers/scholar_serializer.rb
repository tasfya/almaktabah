class ScholarSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :created_at, :updated_at

  has_many :books
  has_many :articles
end
