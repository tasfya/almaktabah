# frozen_string_literal: true

class BenefitSerializer < AppSerializer
  identifier :id

  fields :published_at, :title, :description, :slug

  association :scholar, blueprint: ScholarSerializer

  add_content_field :content_excerpt, :content, format: :plain, truncate: 200
end
