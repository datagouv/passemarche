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

  has_many_attached :documents
  store_accessor :value

  validates :documents, presence: { message: I18n.t('activerecord.errors.json_schema.required') }
  validate :documents_content_type_valid
  validate :documents_size_valid
  validate :documents_name_present
  validate :documents_additional_properties_valid
  validate :documents_object_additional_properties_valid

  def files=(uploaded_files)
    return if uploaded_files.blank?

    uploaded_files.compact_blank.each do |f|
      documents.attach(f) if f.respond_to?(:tempfile) || f.is_a?(ActionDispatch::Http::UploadedFile)
    end
  end

  private

  def documents_content_type_valid
    return if documents.blank?

    documents.each do |doc|
      if doc.content_type.blank?
        errors.add(:documents, I18n.t('activerecord.errors.json_schema.required'))
      elsif ALLOWED_CONTENT_TYPES.exclude?(doc.content_type)
        errors.add(:documents, I18n.t('activerecord.errors.json_schema.invalid'))
      end
    end
  end

  # rubocop:disable Metrics/AbcSize
  def documents_size_valid
    return if documents.blank?

    documents.each do |doc|
      size = doc.byte_size
      if size.blank?
        errors.add(:documents, I18n.t('activerecord.errors.json_schema.required'))
      elsif !size.is_a?(Numeric)
        errors.add(:documents, I18n.t('activerecord.errors.json_schema.wrong_type'))
      elsif !size.positive? || size > MAX_FILE_SIZE
        errors.add(:documents, I18n.t('activerecord.errors.json_schema.invalid'))
      end
    end
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  def documents_name_present
    return if documents.blank?

    documents.each do |doc|
      name = doc.filename.to_s
      if name.blank?
        errors.add(:documents, I18n.t('activerecord.errors.json_schema.required'))
      elsif !name.is_a?(String) || name.length > 255
        errors.add(:documents, I18n.t('activerecord.errors.json_schema.invalid'))
      end
    end
  end
  # rubocop:enable Metrics/AbcSize

  def documents_additional_properties_valid
    return if documents.blank?

    allowed_keys = %w[filename content_type byte_size]
    documents.each do |doc|
      extra_keys = doc.attributes.keys & allowed_keys

      errors.add(:documents, I18n.t('activerecord.errors.json_schema.additional_properties')) if extra_keys.any? { |k| doc.attributes[k].nil? }
    end
  end

  def documents_object_additional_properties_valid
    return if value.blank?

    allowed_keys = ['files']
    extra_keys = value.keys - allowed_keys
    return if extra_keys.empty?

    errors.add(:documents, I18n.t('activerecord.errors.json_schema.additional_properties'))
  end
end
