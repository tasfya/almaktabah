class Avo::Resources::Domain < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :name, as: :text
    field :host, as: :text
    field :logo, as: :file, accept: "image/*", max_size: 5.megabytes
    field :description, as: :textarea
  end
end
