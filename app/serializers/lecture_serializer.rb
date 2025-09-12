# frozen_string_literal: true

class LectureSerializer < AppSerializer
  identifier :id

  fields :title, :description, :category, :duration, :slug, :source_url, :kind

  association :scholar, blueprint: ScholarSerializer

  add_attachment_url_field :thumbnail, :url
  add_attachment_url_field :audio, :url
  add_attachment_url_field :video, :url
end
