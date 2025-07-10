class Avo::Resources::News < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :title, as: :text
    field :content, as: :trix
    field :description, as: :textarea
    field :published, as: :boolean
    field :published_at, as: :date_time, help: "The date and time when this news was published", hide_on: [ :new, :edit ]
    field :thumbnail, as: :file, accept: "image/*", max_size: 5.megabytes
  end
end
