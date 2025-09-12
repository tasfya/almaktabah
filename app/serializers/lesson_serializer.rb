# frozen_string_literal: true

class LessonSerializer < AppSerializer
  identifier :id

  fields :title, :description, :duration, :position, :source_url, :series_id

  association :series, blueprint: SeriesSerializer
  association :scholar, blueprint: ScholarSerializer

  add_attachment_url_field :thumbnail, :url
  add_attachment_url_field :audio, :url
  add_attachment_url_field :video, :url
end
