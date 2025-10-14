# frozen_string_literal: true

class ArticleSerializer < AppSerializer
  identifier :id

  fields :published_at, :title

  association :scholar, blueprint: ScholarSerializer

  add_content_field :content
end
