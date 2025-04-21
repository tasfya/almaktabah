Rails.application.routes.draw do
  constraints subdomain: /.+/ do
    # Routes for subdomains
    get "home/index"
    authenticate :user do
      mount Avo::Engine => "/avo"
    end
    devise_for :users
  end

  # Routes for the main domain
  get "up" => "rails/health#show", :as => :rails_health_check

  root "home#index"
end
