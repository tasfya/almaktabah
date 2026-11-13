class Avo::Resources::DomainAssignment < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :assignable,
        as: :belongs_to,
        polymorphic_as: :assignable,
        types: [ ::Lecture, ::Book, ::Series, ::News, ::Program ]
    field :domain, as: :belongs_to
  end
end
