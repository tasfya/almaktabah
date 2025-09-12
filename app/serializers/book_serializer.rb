# frozen_string_literal: true

class BookSerializer < AppSerializer
  identifier :id

  fields :title, :description, :category, :downloads, :slug

  association :author, blueprint: ScholarSerializer

  add_attachment_url_field :file
  add_attachment_url_field :cover_image
end
