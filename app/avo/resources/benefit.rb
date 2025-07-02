class Avo::Resources::Benefit < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :title, as: :text
    field :description, as: :textarea
    field :content, as: :trix
    field :audio, as: :file, accept: "audio/*"
    field :thumbnail, as: :file, accept: "image/*"
    field :category, as: :text
    field :duration, as: :number
    field :published_date, as: :date
  end
end
