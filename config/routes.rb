require "api/api_constraints"

Rails.application.routes.draw do
  # API documentation
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  namespace :api, defaults: { format: :json } do
    scope module: :v1, constraints: Api::ApiConstraints.new(version: 1, default: true) do
      post "login", to: "authentication#login"
      post "signup", to: "users#create"

      resources :books, only: [ :index, :show ]
      resources :scholars, only: [ :index, :show ]
      resources :articles, only: [ :index, :show ]
      resources :lessons, only: [ :index, :show ] do
        collection do
          get "recent", to: "lessons#recent"
        end
      end

      resources :fatwas, only: [ :index, :show ] do
        collection do
          get "recent", to: "fatwas#recent"
        end
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users
  authenticate :user do
    mount Avo::Engine => "/avo"
  end

  root "home#index"
end
