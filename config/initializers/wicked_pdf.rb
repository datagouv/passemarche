# frozen_string_literal: true

WickedPdf.config ||= {}

if Rails.env.test?
  # Mock wkhtmltopdf for tests
  WickedPdf.config.merge!({
    exe_path: '/usr/local/bin/wkhtmltopdf', # Use echo to mock PDF generation in tests
    enable_local_file_access: true
  })
else
  # Use the bundled wkhtmltopdf binary from wkhtmltopdf-binary gem
  # This removes the dependency on external system installation
  WickedPdf.config[:enable_local_file_access] = true
end
