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
    field :published_date, as: :date
    field :category, as: :text
    field :lessons, as: :has_many
  end
end
