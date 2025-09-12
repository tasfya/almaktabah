# frozen_string_literal: true

class LessonSerializer < AppSerializer
  identifier :id

  fields :published_at, :title, :description, :duration, :position, :source_url, :series_id

  association :series, blueprint: SeriesSerializer
  association :scholar, blueprint: ScholarSerializer

  add_attachment_url_field :thumbnail
  add_attachment_url_field :audio
  add_attachment_url_field :video
end
