Rails.application.routes.draw do
  # API documentation
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  authenticate :user, ->(u) { u.admin? } do
    mount MissionControl::Jobs::Engine => "/jobs"
  end

  # API routes (keep for backward compatibility if needed)
  namespace :api, defaults: { format: :json } do
    scope module: :v1, constraints: Api::ApiConstraints.new(version: 1, default: true) do
      post "login", to: "authentication#login"
      post "signup", to: "users#create"
      get "current_user", to: "users#me"

      resources :books, only: [ :index, :show ] do
        collection do
          get "recent", to: "books#recent"
          get "most_downloaded", to: "books#most_downloaded"
          get "most_viewed", to: "books#most_viewed"
        end
      end

      resources :lectures, only: [ :index, :show ] do
        collection do
          get "recent", to: "lectures#recent"
          get "most_viewed", to: "lectures#most_viewed"
        end
      end

      resources :benefits, only: [ :index, :show ] do
        collection do
          get "recent", to: "benefits#recent"
          get "most_viewed", to: "benefits#most_viewed"
        end
      end

      resources :scholars, only: [ :index, :show ]
      resources :articles, only: [ :index, :show ]
      resources :lessons, only: [ :index, :show ] do
        collection do
          get "recent", to: "lessons#recent"
        end
      end

      resources :series, only: [ :index, :show ] do
      end

      resources :fatwas, only: [ :index, :show ] do
        collection do
          get "recent", to: "fatwas#recent"
        end
      end

      resources :news, only: [ :index, :show ] do
        collection do
          get "recent", to: "news#recent"
        end
      end

      resources :contacts, only: [ :create ]
    end
  end

  # Main web routes (HTML)
  resources :books, only: [ :index, :show ]
  resources :lectures, only: [ :index, :show ]
  resources :lessons, only: [ :index, :show ]
  resources :series, only: [ :index, :show ]
  resources :news, only: [ :index, :show ]
  resources :benefits, only: [ :index, :show ]
  resources :articles, only: [ :index, :show ]
  resources :scholars, only: [ :index, :show ]
  resources :fatwas, only: [ :index, :show ]

  # Static pages
  get "about", to: "about#index"
  get "contact-us", to: "contacts#new", as: :contact
  post "contact-us", to: "contacts#create"

  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users
  authenticate :user do
    mount Avo::Engine => "/avo"

    # Custom routes for Avo
    namespace :avo do
      resources :users do
        member do
          post :generate_api_token
        end
      end
    end
  end

  root "home#index"
end
