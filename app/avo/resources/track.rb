class Avo::Resources::Track < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :title, as: :text
    field :description, as: :textarea
    field :difficulty_level, as: :number
    field :estimated_hours, as: :number
    field :position, as: :number
    field :published, as: :boolean
    field :slug, as: :text
    field :category, as: :number
  end
end
