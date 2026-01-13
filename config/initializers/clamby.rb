Clamby.configure({
  check: false,
  daemonize: false,
  clamscan_path: '/opt/homebrew/bin/clamscan',
  error_clamscan_missing: false,
  error_clamscan_client_error: false,
  error_file_missing: true,
  error_file_virus: false
})
