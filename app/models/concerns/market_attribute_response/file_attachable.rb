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

    uploaded_files.compact_blank.each { |file| attach_file(file) }
  end

  private

  def attach_file(file, metadata: {})
    if file.is_a?(String)
      attach_direct_upload(file, metadata)
    elsif file.respond_to?(:tempfile) || file.is_a?(ActionDispatch::Http::UploadedFile)
      attach_traditional_upload(file, metadata)
      true
    else
      false
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature,
         ActiveRecord::RecordNotFound,
         ActiveStorage::IntegrityError
    errors.add(:documents, I18n.t('activerecord.errors.json_schema.invalid'))
    false
  end

  def attach_direct_upload(signed_id, metadata)
    blob = ActiveStorage::Blob.find_signed!(signed_id)

    blob.update(metadata: blob.metadata.merge(metadata)) if metadata.present?

    # Only attach if not already attached (prevents duplicate key errors on resubmit)
    documents.attach(blob) unless documents.any? { |doc| doc.blob_id == blob.id }
    true
  rescue ActiveSupport::MessageVerifier::InvalidSignature,
         ActiveRecord::RecordNotFound,
         ActiveStorage::IntegrityError
    errors.add(:documents, I18n.t('activerecord.errors.json_schema.invalid'))
    false
  end

  def attach_traditional_upload(file, metadata)
    attachment_params = {
      io: file.respond_to?(:tempfile) ? file.tempfile : file,
      filename: file.original_filename,
      content_type: file.content_type
    }

    attachment_params[:metadata] = metadata if metadata.present?

    documents.attach(attachment_params)
  end

  def validate_attached_files
    return if documents.blank?

    documents.each do |doc|
      validate_file_content_type(doc)
      validate_file_size(doc)
      validate_file_name(doc)
    end
  end

  def validate_file_content_type(doc)
    return add_document_error('required') if doc.content_type.blank?

    add_document_error('invalid') if ALLOWED_CONTENT_TYPES.exclude?(doc.content_type)
  end

  def validate_file_size(doc)
    size = doc.byte_size
    return add_document_error('required') if size.blank?
    return add_document_error('wrong_type') unless size.is_a?(Numeric)

    add_document_error('invalid') unless size.positive? && size <= MAX_FILE_SIZE
  end

  def validate_file_name(doc)
    name = doc.filename.to_s
    return add_document_error('required') if name.blank?

    add_document_error('invalid') if !name.is_a?(String) || name.length > 255
  end

  def add_document_error(message_key)
    errors.add(:documents, I18n.t("activerecord.errors.json_schema.#{message_key}"))
  end
end
