Rails.application.routes.draw do
  authenticate :user, ->(u) { u.admin? } do
    mount MissionControl::Jobs::Engine => "/jobs"
  end

  resources :books, only: [ :index, :show ]
  resources :lectures, only: [ :index, :show ] do
    member do
      get :play
    end
  end
  resources :lessons, only: [ :index, :show ] do
    member do
      get :play
    end
  end
  resources :series, only: [ :index, :show ]
  resources :news, only: [ :index, :show ]
  resources :benefits, only: [ :index, :show ] do
    member do
      get :play
    end
  end
  resources :articles, only: [ :index, :show ]
  resources :scholars, only: [ :index, :show ]
  resources :fatwas, only: [ :index, :show ]

  get "search", to: "search#index"

  # Static pages
  get "about", to: "about#index"
  get "contact-us", to: "contacts#new", as: :contact
  post "contact-us", to: "contacts#create"

  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users
  authenticate :user do
    mount Avo::Engine => "/avo"
  end

  root "home#index"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "spotify_search", to: "spotify_search#index"
  get "spotify", to: "spotify#index"
  get "library", to: "library#index"
  get "playlist/:id", to: "playlist#show", as: "playlist"
  get "category/:id", to: "category#show", as: "category"
  get "artist/:id", to: "artist#show", as: "artist"
  get "album/:id", to: "album#show", as: "album"
end
