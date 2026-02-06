# frozen_string_literal: true

clamscan_path = Rails.application.credentials.dig(:clamav, :clamscan_path)

Clamby.configure(
  check: false,
  daemonize: false,
  clamscan_path:,
  # --- Security ---
  error_file_virus: true,
  error_file_missing: true,
  # --- Infra ---
  error_clamscan_missing: false,
  error_clamscan_client_error: false
)
