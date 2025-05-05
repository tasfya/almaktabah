class ArticleSerializer < ActiveModel::Serializer
  attributes :id, :title, :created_at, :updated_at

  belongs_to :author, serializer: ScholarSerializer
end
