# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.eager_load = true
  config.enable_reloading = false

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.smtp_settings = {
    address: 'smtp-relay.brevo.com',
    port: 587,
    authentication: :login,
    user_name: ENV.fetch('BREVO_SMTP_LOGIN'),
    password: ENV.fetch('BREVO_SMTP_PASSWORD')
  }
  config.action_mailer.default_url_options = { host: ENV.fetch('APP_HOST'), protocol: 'https' }
  config.action_mailer.asset_host = "https://#{ENV.fetch('APP_HOST')}"

  config.action_controller.default_url_options = { host: ENV.fetch('APP_HOST'), protocol: 'https' }
end
