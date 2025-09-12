# frozen_string_literal: true

class FatwaSerializer < AppSerializer
  identifier :id

  fields :published_at, :title, :category, :slug, :source_url

  add_content_field :question, format: :plain
  add_content_field :answer, format: :plain

  association :scholar, blueprint: ScholarSerializer
end
