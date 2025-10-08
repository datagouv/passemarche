Sentry.init do |config|
  config.dsn = Rails.application.credentials.sentry_dsn
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.enabled_environments = %w[sandbox]

  config.traces_sample_rate = 1.0
end
