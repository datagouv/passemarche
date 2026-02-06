# frozen_string_literal: true

clamscan_path = Rails.application.credentials.dig(:clamav, :clamscan_path) ||
                ENV.fetch('CLAMAV_CLAMSCAN_PATH', '/usr/bin/clamscan')

secure_mode = Rails.env.production?

Clamby.configure(
  check: secure_mode,                 # checks clamscan at boot in production
  daemonize: false,
  clamscan_path:,
  # --- Security ---
  error_file_virus: true,
  error_file_missing: true,
  # --- Infra ---
  error_clamscan_missing: secure_mode,
  error_clamscan_client_error: secure_mode
)
