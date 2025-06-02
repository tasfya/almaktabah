class Avo::Resources::ApiToken < Avo::BaseResource
  self.title = :display_name
  self.includes = [ :user ]

  def fields
    field :id, as: :id
    field :token, as: :text, help: "The API token used for authentication"
    field :purpose, as: :text, help: "What this token is used for (e.g., 'Frontend API', 'Mobile App')"
    field :user, as: :belongs_to
    field :active, as: :boolean
    field :last_used_at, as: :date_time
    field :expires_at, as: :date_time
    field :created_at, as: :date_time
    field :updated_at, as: :date_time
  end
end
