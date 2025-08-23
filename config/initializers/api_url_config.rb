# frozen_string_literal: true

Rails.application.configure do
  # API URL configuration for webhooks and external links
  # This should be set via environment variables in production
  config.api_base_url = ENV.fetch('API_BASE_URL') do
    case Rails.env
    when 'sandbox'
      # Production should always have API_BASE_URL set
      raise 'API_BASE_URL environment variable is required in production'
    else
      'http://localhost:3000'
    end
  end
end
