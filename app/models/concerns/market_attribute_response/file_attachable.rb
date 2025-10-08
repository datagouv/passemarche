# frozen_string_literal: true

module MarketAttributeResponse::FileAttachable
  extend ActiveSupport::Concern

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

  included do
    has_many_attached :documents
    validate :validate_attached_files
  end

  def files=(uploaded_files)
    return if uploaded_files.blank?

    uploaded_files.compact_blank.each do |f|
      next unless f.respond_to?(:tempfile) || f.is_a?(ActionDispatch::Http::UploadedFile)

      documents.attach(
        io: f.respond_to?(:tempfile) ? f.tempfile : f,
        filename: f.original_filename,
        content_type: f.content_type,
        metadata: { field_type: 'generic' }
      )
    end
  end

  class_methods do
    def file_attachable?
      true
    end
  end

  private

  def validate_attached_files
    return if documents.blank?

    documents.each do |doc|
      validate_file_content_type(doc)
      validate_file_size(doc)
      validate_file_name(doc)
    end
  end

  def validate_file_content_type(doc)
    if doc.content_type.blank?
      errors.add(:documents, I18n.t('activerecord.errors.json_schema.required'))
    elsif ALLOWED_CONTENT_TYPES.exclude?(doc.content_type)
      errors.add(:documents, I18n.t('activerecord.errors.json_schema.invalid'))
    end
  end

  def validate_file_size(doc)
    size = doc.byte_size
    if size.blank?
      errors.add(:documents, I18n.t('activerecord.errors.json_schema.required'))
    elsif !size.is_a?(Numeric)
      errors.add(:documents, I18n.t('activerecord.errors.json_schema.wrong_type'))
    elsif !size.positive? || size > MAX_FILE_SIZE
      errors.add(:documents, I18n.t('activerecord.errors.json_schema.invalid'))
    end
  end

  def validate_file_name(doc)
    name = doc.filename.to_s
    if name.blank?
      errors.add(:documents, I18n.t('activerecord.errors.json_schema.required'))
    elsif !name.is_a?(String) || name.length > 255
      errors.add(:documents, I18n.t('activerecord.errors.json_schema.invalid'))
    end
  end
end
