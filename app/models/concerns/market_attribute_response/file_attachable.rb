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
    text/plain
  ].freeze

  included do
    has_many_attached :documents
    validate :validate_attached_files
  end

  def files=(uploaded_files)
    return if uploaded_files.blank?

    clean_files = uploaded_files.compact_blank.reject { |f| f.is_a?(String) && f.strip.empty? }

    return if clean_files.empty?

    clean_files.each_with_index do |file, _index|
      attach_file(file)
    end
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
    blob = find_and_update_blob(signed_id, metadata)
    return true if already_attached?(blob)

    documents.attach(blob)
    enqueue_scan_for(blob)
    true
  rescue ActiveSupport::MessageVerifier::InvalidSignature,
         ActiveRecord::RecordNotFound,
         ActiveStorage::IntegrityError => e
    handle_blob_attachment_error(e)
  end

  def handle_blob_attachment_error(_error)
    errors.add(:documents, I18n.t('activerecord.errors.json_schema.invalid'))
    false
  end

  def find_and_update_blob(signed_id, metadata)
    blob = ActiveStorage::Blob.find_signed!(signed_id)
    blob.update(metadata: blob.metadata.merge(metadata)) if metadata.present?
    blob
  end

  def already_attached?(blob)
    documents.any? { |doc| doc.blob_id == blob.id }
  end

  def enqueue_scan_for(blob)
    attachment = documents.find { |doc| doc.blob_id == blob.id }
    return unless attachment

    ScanDocumentJob.perform_later(blob.id)
  end

  def attach_traditional_upload(file, metadata)
    attachment_params = {
      io: file.respond_to?(:tempfile) ? file.tempfile : file,
      filename: file.original_filename,
      content_type: file.content_type
    }

    attachment_params[:metadata] = metadata if metadata.present?

    attachment = documents.attach(attachment_params)
    enqueue_scan_for(attachment.first.blob) if attachment.present?
  end

  def validate_attached_files
    return if documents.blank?

    documents.each do |doc|
      validate_file_content_type(doc)
      validate_file_size(doc)
      validate_file_name(doc)
      should_validate = should_validate_security?
      validate_file_security(doc) if should_validate
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

  def enqueue_document_scans
    documents.each do |document|
      next if document.blob.metadata.key?('scan_safe') || document.blob.metadata.key?('scanned_at')

      ScanDocumentJob.perform_later(document.id)
    end
  end

  def validate_file_security(doc)
    metadata = doc.blob.metadata

    # Allow safe files
    return if metadata['scan_safe'] == true

    # Block submission if file not yet scanned (security scan in progress)
    unless metadata.key?('scan_safe')
      errors.add(:base, "#{doc.filename} : Le scan de sécurité est en cours. Veuillez patienter quelques instants avant de soumettre.")
      return
    end

    # Block submission if malware detected
    return if metadata['scan_safe'] != false

    error_msg = metadata['scan_error'] || 'Fichier bloqué pour raison de sécurité'
    errors.add(:base, "#{doc.filename} : #{error_msg}")
  end

  def should_validate_security?
    # Check ActiveModel validation context (set during validation)
    # This will be :summary when market_application.valid?(:summary) is called
    context = resolved_validation_context

    return false if context.blank?

    # Only validate at summary
    context.to_s == 'summary'
  end
end

def resolved_validation_context
  context = validation_context
  context ||= market_application&.validation_context if respond_to?(:market_application)
  context
end
