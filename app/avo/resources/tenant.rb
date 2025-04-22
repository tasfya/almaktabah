class Avo::Resources::Tenant < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :subdomain, as: :text
    field :name, as: :text
    field :logo_light, as: :file
    field :logo_dark, as: :file
  end
end
