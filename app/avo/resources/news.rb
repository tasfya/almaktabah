class Avo::Resources::News < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }
  
  def fields
    field :id, as: :id
    field :title, as: :text
    field :content, as: :textarea
    field :description, as: :textarea
    field :published_at, as: :date_time
    field :thumbnail, at: :file
  end
end
