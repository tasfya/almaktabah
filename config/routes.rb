Rails.application.routes.draw do
  constraints subdomain: /.+/ do
    get "home/index"
  end

  authenticate :user do
    mount Avo::Engine => "/avo"
  end
  devise_for :users

  get "up" => "rails/health#show", :as => :rails_health_check
  root "home#index"
end
