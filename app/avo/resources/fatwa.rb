class Avo::Resources::Fatwa < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :title, as: :text
    field :category, as: :text
    field :question, as: :trix
    field :answer, as: :trix
    field :published, as: :boolean
    field :published_at, as: :date_time, help: "The date and time when this fatwa was published", hide_on: [ :new, :edit ]
  end
end
