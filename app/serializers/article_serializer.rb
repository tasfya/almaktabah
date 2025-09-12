# frozen_string_literal: true

class ArticleSerializer < AppSerializer
  identifier :id

  fields :title

  association :author, blueprint: ScholarSerializer

  add_content_field :content
end
