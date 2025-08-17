class Avo::Resources::Series < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :title, as: :text
    field :description, as: :textarea
    field :category, as: :text
    field :published, as: :boolean
    field :published_at, as: :date_time, help: "The date and time when this series was published", hide_on: [ :new, :edit ]
    field :lessons, as: :has_many
    field :scholar, as: :belongs_to
  end
end
