Rails.application.routes.draw do
  authenticate :user, ->(u) { u.admin? } do
    mount MissionControl::Jobs::Engine => "/jobs"
  end

  resources :books, only: [ :index ]
  resources :lectures, only: [ :index ]
  resources :series, only: [ :index ]
  resources :benefits, only: [ :index ]
  resources :articles, only: [ :index ]

  scope "scholar/:scholar_id" do
    resources :books, only: [ :show ], controller: "books"
    resources :benefits, only: [ :show ], controller: "benefits"
    resources :articles, only: [ :show ], controller: "articles"
    resources :series, only: [ :show ], controller: "series"
    get "lectures(/:kind)/:id", to: "lectures#show", as: "lecture"
  end

  resources :news, only: [ :index, :show ]
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
