# frozen_string_literal: true

Rails.application.configure do
  config.file_upload = ActiveSupport::OrderedOptions.new

  config.file_upload.max_size = 100.megabytes
  config.file_upload.allowed_types = {
    'pdf' => ['application/pdf'],
    'doc' => ['application/msword'],
    'docx' => ['application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
    'txt' => ['text/plain'],
    'xls' => ['application/vnd.ms-excel'],
    'xlsx' => ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'],
    'csv' => ['text/csv', 'application/csv'],
    'jpg' => ['image/jpeg'],
    'jpeg' => ['image/jpeg'],
    'png' => ['image/png'],
    'gif' => ['image/gif'],
    'zip' => ['application/zip', 'application/x-zip-compressed']
  }.freeze

  # Helpers
  config.file_upload.allowed_extensions =
    config.file_upload.allowed_types.keys.freeze
  config.file_upload.allowed_content_types =
    config.file_upload.allowed_types.values.flatten.uniq.freeze
end
