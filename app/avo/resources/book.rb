class Avo::Resources::Book < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :title, as: :text
    field :description, as: :text
    field :category, as: :text
    field :published, as: :boolean
    field :published_at, as: :date_time, help: "The date and time when this book was published", hide_on: [ :new, :edit ]
    field :downloads, as: :number
    field :file, as: :file
    field :cover_image, as: :file
    field :author, as: :belongs_to
  end
end
