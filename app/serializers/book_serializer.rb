# frozen_string_literal: true

class BookSerializer < AppSerializer
  identifier :id

  fields :published_at, :title, :description, :category, :downloads, :slug

  association :scholar, blueprint: ScholarSerializer

  add_attachment_url_field :file
  add_attachment_url_field :cover_image
end
