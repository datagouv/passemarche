# frozen_string_literal: true

unless Rails.env.local? || Rails.env.sandbox?
  Rails.application.config.action_mailer.delivery_method = :smtp
  Rails.application.config.action_mailer.smtp_settings = {
    address: 'smtp-relay.brevo.com',
    port: 587,
    authentication: :plain,
    user_name: Rails.application.credentials.dig(:brevo, :smtp_login),
    password: Rails.application.credentials.dig(:brevo, :smtp_password)
  }
end
