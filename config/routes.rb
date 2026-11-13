Rails.application.routes.draw do
  namespace :api do
    get "lectures/pending_downloads", to: "lectures#pending_downloads"
    post "lectures/:id/upload_video", to: "lectures#upload_video"

    get "lessons/pending_downloads", to: "lessons#pending_downloads"
    post "lessons/:id/upload_video", to: "lessons#upload_video"

    get "transcriptions/pending", to: "transcriptions#pending"
    post "transcriptions/:type/:id/upload", to: "transcriptions#upload"
  end

  get "/robots.txt", to: "robots#show", defaults: { format: "text" }
  get "/sitemap.xml", to: "sitemaps#index", defaults: { format: "xml" }
  get "/sitemaps/:type(-:page).xml", to: "sitemaps#show",
      defaults: { format: "xml" },
      constraints: { type: Regexp.new(SitemapService::CONTENT_TYPES.keys.join("|")), page: /\d+/ },
      as: :sitemap_content

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
    resources :series, only: [ :show ], path: I18n.t("routes.series", default: "series") do
      resources :lessons, only: [ :show ], path: I18n.t("routes.lessons", default: "lessons")
    end
    resources :news, only: [ :show ], path: I18n.t("routes.news", default: "news")
    resources :fatwas, only: [ :show ], path: I18n.t("routes.fatwas", default: "fatwas")
    get "#{I18n.t("routes.lectures", default: "lectures")}/(:kind)/:id", to: "lectures#show", as: "lecture"
  end

  # Legacy: Arabic-path lessons redirects
  get I18n.t("routes.lessons", default: "lessons"), to: "lessons#legacy_index_redirect"
  get "#{I18n.t("routes.lessons", default: "lessons")}/:id", to: "lessons#legacy_redirect"

  # Legacy: English index paths → Arabic equivalents (301)
  %w[lectures fatwas news].each do |eng|
    arabic = I18n.t("routes.#{eng}", default: eng)
    next if eng == arabic
    encoded = URI::DEFAULT_PARSER.escape(arabic)
    get eng, to: redirect { |_, req|
      qs = req.query_string.present? ? "?#{req.query_string}" : ""
      "/#{encoded}#{qs}"
    }, as: nil
  end

  # Legacy: English lessons → series index
  get "lessons", to: "lessons#legacy_index_redirect", as: nil

  get "#{I18n.t("routes.news", default: "news")}/:id", to: "news#legacy_redirect", as: :legacy_news
  get "#{I18n.t("routes.fatwas", default: "fatwas")}/:id", to: "fatwas#legacy_redirect", as: :legacy_fatwa

  # Legacy: English show paths
  get "news/:id", to: "news#legacy_redirect", as: nil
  get "fatwas/:id", to: "fatwas#legacy_redirect", as: nil
  get "books/:id", to: "books#legacy_redirect", constraints: { id: /\d+/ }
  get "series/:id", to: "series#legacy_redirect", constraints: { id: /\d+/ }
  get "lectures/:id", to: "lectures#legacy_redirect", constraints: { id: /\d+/ }
  resources :news, only: [ :index ], path: I18n.t("routes.news", default: "news")
  resources :fatwas, only: [ :index ], path: I18n.t("routes.fatwas", default: "fatwas")

  # Generic play route for all playable resources
  get "play/:resource_type/:id", to: "play#show", as: "play"
  get "play/stop", to: "play#stop", as: "stop_play"

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

  # Learner accounts and programs, behind the config.x.learners_enabled launch
  # switch. Always drawn (so the Devise learner helpers exist everywhere) but
  # matched only while the switch is on; otherwise these paths 404.
  # Drawn after `devise_for :users` so staff stay Devise's default scope.
  constraints(->(_request) { Rails.configuration.x.learners_enabled }) do
    # Password reset and confirmation mail need a mail provider; until then
    # those routes stay undrawn.
    devise_for :learners, controllers: { sessions: "learners/sessions", passwords: "learners/passwords", confirmations: "learners/confirmations" },
      skip: [ :registrations, *([ :passwords, :confirmations ] unless Rails.configuration.x.learner_mail_enabled) ]
    devise_scope :learner do
      resource :registration, only: [ :new, :create ], path: "learners",
        path_names: { new: "sign_up" }, controller: "learners/registrations", as: :learner_registration
    end

    resources :programs, only: [ :index, :show ], path: I18n.t("routes.programs", default: "programs") do
      resources :enrollments, only: :create
    end
    resources :certificates, only: :show, path: I18n.t("routes.certificates", default: "certificates")

    scope "my", module: "learner_area" do
      get "/", to: "dashboard#show", as: :learner_dashboard
      resources :cohorts, only: :show, as: :learner_cohorts do
        resources :completions, only: [ :create, :destroy ]
        get "play/:program_item_id", to: "plays#show", as: :play
        resource :reminders, only: :update
        resources :exams, only: :show do
          post :submit, on: :member
        end
      end
      resource :account, only: [ :show, :update, :destroy ], as: :learner_account
    end
  end

  root "home#index"

  get "/podcasts/feed", to: "podcasts#feed", as: "podcast_feed", defaults: { format: "xml" }
end
