# frozen_string_literal: true

WickedPdf.config ||= {}

gem_binary_path = Gem.bin_path('wkhtmltopdf-binary', 'wkhtmltopdf')
WickedPdf.config.merge!({
  exe_path: gem_binary_path,
  enable_local_file_access: true
})
