# frozen_string_literal: true

class NewsSerializer < AppSerializer
  identifier :id

  fields :published_at, :title, :description, :slug

  add_content_field :content_excerpt, :content, format: :plain, truncate: 200
  add_attachment_url_field :thumbnail
end
