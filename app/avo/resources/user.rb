class Avo::Resources::User < Avo::BaseResource
  self.title = :email

  def fields
    field :id, as: :id
    field :email, as: :text
    field :admin, as: :boolean
    field :actions, as: :heading
  end
end
