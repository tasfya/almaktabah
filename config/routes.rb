Rails.application.routes.draw do
  authenticate :user, ->(u) { u.admin? } do
    mount MissionControl::Jobs::Engine => "/jobs"
  end

  resources :books, only: [ :index ], path: I18n.t("routes.books", default: "books")
  resources :lectures, only: [ :index ], path: I18n.t("routes.lectures", default: "lectures")
  resources :series, only: [ :index ], path: I18n.t("routes.series", default: "series")
  resources :articles, only: [ :index ], path: I18n.t("routes.articles", default: "articles")

  scope ":scholar_id" do
    resources :books, only: [ :show ], path: I18n.t("routes.books", default: "books")
    resources :articles, only: [ :show ], path: I18n.t("routes.articles", default: "articles")
    resources :series, only: [ :show ], path: I18n.t("routes.series", default: "series")
    get "#{I18n.t("routes.lectures", default: "lectures")}/(:kind)/:id", to: "lectures#show", as: "lecture"
  end

  resources :lessons, only: [ :index, :show ], path: I18n.t("routes.lessons", default: "lessons")
  resources :news, only: [ :index, :show ], path: I18n.t("routes.news", default: "news")
  resources :scholars, only: [ :index, :show ], path: I18n.t("routes.scholars", default: "scholars")
  resources :fatwas, only: [ :index, :show ], path: I18n.t("routes.fatwas", default: "fatwas")

  # Generic play route for all playable resources
  post "play/:resource_type/:id", to: "play#show", as: "play"
  delete "play/stop", to: "play#stop", as: "stop_play"

  get "search", to: "search#index"

  # Static pages
  get "about", to: "about#index"

  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.development?
    get "theme-playground", to: "theme_playground#index"
  end

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
