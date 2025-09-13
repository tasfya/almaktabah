# frozen_string_literal: true

class ScholarSerializer < AppSerializer
  identifier :id

  fields :published_at, :first_name, :last_name, :slug, :full_name_alias

  field :full_name do |scholar|
    scholar.name
  end

  add_content_field :bio
end
