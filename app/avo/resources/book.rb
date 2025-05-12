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
    field :published_date, as: :date
    field :views, as: :number
    field :downloads, as: :number
    field :file, as: :file
    field :cover_image, as: :file
    field :author, as: :belongs_to
  end
end
