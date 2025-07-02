Rails.application.routes.draw do
  authenticate :user, ->(u) { u.admin? } do
    mount MissionControl::Jobs::Engine => "/jobs"
  end

  resources :books, only: [ :index, :show ]
  resources :lectures, only: [ :index, :show ]
  resources :lessons, only: [ :index, :show ]
  resources :series, only: [ :index, :show ]
  resources :news, only: [ :index, :show ]
  resources :benefits, only: [ :index, :show ]
  resources :articles, only: [ :index, :show ]
  resources :scholars, only: [ :index, :show ]
  resources :fatwas, only: [ :index, :show ]

  get "about", to: "pages#about"
  get "contact", to: "pages#contact"
  post "contact", to: "pages#create_contact"

  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users
  authenticate :user do
    mount Avo::Engine => "/avo"
  end

  root "home#index"
end
