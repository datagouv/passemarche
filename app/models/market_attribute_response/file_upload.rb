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

  has_one_attached :document
  store_accessor :value, :file

  def file=(uploaded_file)
    return if uploaded_file.blank?

    # Attach the actual file to Active Storage (skip for test doubles)
    document.attach(uploaded_file) if uploaded_file.respond_to?(:tempfile) || uploaded_file.is_a?(ActionDispatch::Http::UploadedFile)

    # Store metadata for quick access without loading the blob
    write_store_attribute(:value, :file, {
      'name' => uploaded_file.original_filename,
      'content_type' => uploaded_file.content_type,
      'size' => uploaded_file.size
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
