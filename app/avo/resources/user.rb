class Avo::Resources::User < Avo::BaseResource
  self.title = :email
  
  def fields
    field :id, as: :id
    field :email, as: :text
    field :admin, as: :boolean
    
    field :api_tokens, as: :has_many

    field :actions, as: :heading
    
    field :generate_token, as: :text, hide_on: [:forms, :index, :show] do
      # This is just a placeholder for the custom action button
    end
  end
  
  def actions
    action Avo::Actions::GenerateApiToken
  end
end
