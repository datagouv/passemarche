# frozen_string_literal: true

WickedPdf.config ||= {}

if Rails.env.test?
  # Mock wkhtmltopdf for tests
  WickedPdf.config.merge!({
    exe_path: '/bin/echo', # Use echo to mock PDF generation in tests
    enable_local_file_access: true
  })
else
  # Use the actual wkhtmltopdf installation
  WickedPdf.config.merge!({
    exe_path: '/usr/bin/wkhtmltopdf',
    enable_local_file_access: true,
    wkhtmltopdf: '/usr/bin/wkhtmltopdf'
  })
end