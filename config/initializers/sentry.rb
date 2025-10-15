if Rails.env.production?
  Sentry.init do |config|
    config.breadcrumbs_logger = [ :active_support_logger ]
    config.dsn = Rails.application.credentials.dig(:sentry, :dsn)
    config.traces_sample_rate = 1.0
    # Enable sending logs to Sentry
    config.enable_logs = true
    # Patch Ruby logger to forward logs
    config.enabled_patches = [ :logger ]
  end
end
