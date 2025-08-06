Rails.application.routes.draw do
  authenticate :user, ->(u) { u.admin? } do
    mount MissionControl::Jobs::Engine => "/jobs"
  end

  resources :books, only: [ :index, :show ]
  resources :lectures, only: [ :index, :show ]
  resources :lessons, only: [ :show ]
  resources :series, only: [ :index, :show ]
  resources :news, only: [ :index, :show ]
  resources :benefits, only: [ :index, :show ]
  resources :articles, only: [ :index, :show ]
  resources :scholars, only: [ :index, :show ]
  resources :fatwas, only: [ :index, :show ]

  # Generic play route for all playable resources
  post "play/:resource_type/:id", to: "play#show", as: "play"
  delete "play/stop", to: "play#stop", as: "stop_play"

  get "search", to: "search#index"

  # Static pages
  get "about", to: "about#index"

  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users, skip: [ :registrations ]
  authenticate :user do
    mount Avo::Engine => "/avo"
  end

  root "home#index"

  get "library", to: "library#index"
  get "playlist/:id", to: "playlist#show", as: "playlist"
  get "category/:id", to: "category#show", as: "category"
  get "artist/:id", to: "artist#show", as: "artist"
  get "album/:id", to: "album#show", as: "album"

  get "/podcasts/feed", to: "podcasts#feed", as: "podcast_feed", defaults: { format: "xml" }
end
