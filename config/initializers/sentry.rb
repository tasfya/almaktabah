# frozen_string_literal: true

Sentry.init do |config|
  config.breadcrumbs_logger = [ :active_support_logger ]
  config.dsn = Rails.application.credentials.dig(:sentry, :dsn)
  config.traces_sample_rate = 1.0
end
