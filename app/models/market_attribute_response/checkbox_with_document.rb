class MarketAttributeResponse::CheckboxWithDocument < MarketAttributeResponse::Checkbox
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
  store_accessor :value, :checked

  validate :documents_only_if_checked
  validate :file_metadata_valid, if: -> { documents.attached? }

  def files=(uploaded_files)
    return unless checked
    return if uploaded_files.blank?

    uploaded_files
      .compact_blank
      .each do |f|
      documents.attach(f)
    end
  end

  def checked
    ActiveModel::Type::Boolean.new.cast(super)
  end

  private

  def documents_only_if_checked
    return unless documents.attached? && !checked

    errors.add(:documents, :document_not_allowed_unless_checked)
  end

  def file_metadata_valid
    documents.each do |doc|
      blob = doc.blob

      errors.add(:documents, I18n.t('activerecord.errors.json_schema.invalid')) if blob.byte_size > MAX_FILE_SIZE

      errors.add(:documents, I18n.t('activerecord.errors.json_schema.invalid')) unless ALLOWED_CONTENT_TYPES.include?(blob.content_type)
    end
  end
end
