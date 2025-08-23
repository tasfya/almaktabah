class Avo::Resources::Scholar < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :first_name, as: :text
    field :full_name, as: :text
    field :full_name_alias, as: :text
    field :last_name, as: :text
    field :bio, as: :trix
    field :published, as: :boolean
    field :published_at, as: :date_time, help: "The date and time when this scholar was published", hide_on: [ :new, :edit ]
  end
end
