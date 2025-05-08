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
    field :views, as: :number
    field :question, as: :trix
    field :answer, as: :trix
    field :published_date, as: :date
  end
end
