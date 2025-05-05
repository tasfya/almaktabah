class Avo::Resources::Lesson < Avo::BaseResource
  self.model_class = "Lesson"
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
    field :published_date, as: :date
    field :duration, as: :number
    field :category, as: :text
    field :thumbnail, as: :file, accept: "image/*", max_size: 5.megabytes
    field :audio, as: :file, accept: "audio/*", max_size: 10.megabytes
  end
end
