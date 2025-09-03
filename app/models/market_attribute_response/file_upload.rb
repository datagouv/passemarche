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

  validate :file_field_required
  validate :file_structure_valid
  validate :file_content_type_valid
  validate :file_size_valid
  validate :file_name_present
  validate :file_additional_properties_valid
  validate :file_object_additional_properties_valid

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

  private

  def file_field_required
    return unless value.blank? || !value.key?('file')

    errors.add(:file, I18n.t('activerecord.errors.json_schema.required'))
  end

  def file_structure_valid
    return if value.blank? || !value.key?('file')
    return if file.is_a?(Hash)

    errors.add(:file, I18n.t('activerecord.errors.json_schema.wrong_type'))
  end

  # rubocop:disable Metrics/AbcSize
  def file_content_type_valid
    return if value.blank? || !value.key?('file') || !file.is_a?(Hash)

    content_type = file['content_type']

    # Content type is required
    if content_type.blank?
      errors.add(:file, I18n.t('activerecord.errors.json_schema.required'))
      return
    end

    # Content type must be allowed
    return if ALLOWED_CONTENT_TYPES.include?(content_type)

    errors.add(:file, I18n.t('activerecord.errors.json_schema.invalid'))
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  def file_size_valid
    return if value.blank? || !value.key?('file') || !file.is_a?(Hash)

    size = file['size']

    # Size is required
    if size.blank?
      errors.add(:file, I18n.t('activerecord.errors.json_schema.required'))
      return
    end

    # Size must be numeric
    unless size.is_a?(Numeric)
      errors.add(:file, I18n.t('activerecord.errors.json_schema.wrong_type'))
      return
    end

    # Size must be valid range
    return if size.positive? && size <= MAX_FILE_SIZE

    errors.add(:file, I18n.t('activerecord.errors.json_schema.invalid'))
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  def file_name_present
    return if value.blank? || !value.key?('file') || !file.is_a?(Hash)

    name = file['name']

    # Name is required
    if name.blank?
      errors.add(:file, I18n.t('activerecord.errors.json_schema.required'))
      return
    end

    # Name must be string and within length
    return if name.is_a?(String) && name.length <= 255

    errors.add(:file, I18n.t('activerecord.errors.json_schema.invalid'))
  end
  # rubocop:enable Metrics/AbcSize

  def file_additional_properties_valid
    return if value.blank? || !value.key?('file') || !file.is_a?(Hash)

    allowed_keys = %w[name content_type size]
    extra_keys = file.keys - allowed_keys

    return if extra_keys.empty?

    errors.add(:file, I18n.t('activerecord.errors.json_schema.additional_properties'))
  end

  def file_object_additional_properties_valid
    return if value.blank?

    allowed_keys = ['file']
    extra_keys = value.keys - allowed_keys

    return if extra_keys.empty?

    errors.add(:file, I18n.t('activerecord.errors.json_schema.additional_properties'))
  end
end
