class ArticleSerializer < ActiveModel::Serializer
  attributes :id, :title, :content, :created_at, :updated_at

  belongs_to :scholar
end
