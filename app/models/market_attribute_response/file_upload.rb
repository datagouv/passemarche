class MarketAttributeResponse::FileUpload < MarketAttributeResponse
  MAX_FILE_SIZE = 100.megabytes
  ALLOWED_CONTENT_TYPES = %w[
    application/pdf
    image/jpeg
    image/png
    image/gif
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.ms-excel
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  ].freeze

  def value_file
    value&.dig('file')
  end

  def value_file=(file)
    return if file.blank?

    self.value = (value || {}).merge('file' => {
      'name' => file.original_filename,
      'content_type' => file.content_type,
      'size' => file.size
    })
  end

  protected

  def json_schema
    {
      type: 'object',
      required: ['file'],
      properties: {
        file: {
          type: 'object',
          required: %w[name content_type size],
          properties: {
            name: {
              type: 'string',
              maxLength: 255
            },
            content_type: {
              type: 'string',
              enum: ALLOWED_CONTENT_TYPES
            },
            size: {
              type: 'integer',
              minimum: 1,
              maximum: MAX_FILE_SIZE
            }
          },
          additionalProperties: false
        }
      },
      additionalProperties: false
    }
  end
end
