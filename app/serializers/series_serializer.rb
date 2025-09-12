# frozen_string_literal: true

class SeriesSerializer < AppSerializer
  identifier :id

  fields :published_at, :title, :description, :category, :slug, :published

  association :scholar, blueprint: ScholarSerializer

  field :lessons_count do |series|
    series.lessons.count
  end

  add_attachment_url_field :explainable
end
