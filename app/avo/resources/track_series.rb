class Avo::Resources::TrackSeries < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :track, as: :belongs_to
    field :series, as: :belongs_to
    field :position, as: :number
  end
end
