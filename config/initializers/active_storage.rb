# frozen_string_literal: true

# Configure ActiveStorage URL expiration for attestation downloads
# Default is 5 minutes, we extend to 48 hours for user convenience
Rails.application.configure do
  config.active_storage.urls_expire_in = 24.hours
end
