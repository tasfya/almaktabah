source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

gem "tailwindcss-rails"

# Use sqlite3 as the database for Active Record
gem "sqlite3", ">= 2.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Pagination
gem "pagy", "~> 9.4"

# Search and indexing
gem "typesense-rails", "~> 1.0.0.rc1"

# Filtering and searching
gem "ransack", "~> 4.4"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

gem "devise"
gem "database_validations"
gem "database_consistency"
gem "aws-sdk-s3", require: false
gem "sentry-ruby"
gem "sentry-rails"
gem "streamio-ffmpeg"
gem "mission_control-jobs"
gem "rswag-api"
gem "rswag-ui"
gem "blueprinter"
gem "blueprinter-activerecord"

# YouTube video downloader and HTTP requests
gem "httparty"

# friendly_id for human-readable URLs
gem "friendly_id", "~> 5.5.0"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop"
  gem "rubocop-rails-omakase", require: false

  gem "rspec-rails"
  gem "rswag-specs"
  gem "shoulda-matchers"
  gem "factory_bot_rails"
  gem "faker"
  gem "simplecov"
  gem "simplecov-cobertura"
  gem "rubocop-factory_bot"
  gem "rubocop-rspec"
  gem "rubocop-rspec_rails"
  gem "rspec-instafail", require: false
  gem "fuubar", require: false
  gem "rails-controller-testing"
  gem "rspec-github", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  gem "overcommit", require: false
end

gem "ruby-progressbar"
gem "avo", ">= 3.2"
gem "rails_icons", "~> 1.4"
gem "nice_partials", "~> 0.10.1"
gem "importmap-rails"
