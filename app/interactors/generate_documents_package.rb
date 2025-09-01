# frozen_string_literal: true

require 'zip'

class GenerateDocumentsPackage < ApplicationInteractor
  delegate :market_application, to: :context

  def call
    validate_prerequisites
    attach_documents_package
  end

  private

  def validate_prerequisites
    context.fail!(message: 'Attestation requise pour créer le package') unless market_application.attestation.attached?
    context.fail!(message: 'Documents package déjà généré') if market_application.documents_package.attached?
  end

  def attach_documents_package
    zip_content = generate_zip_content

    market_application.documents_package.attach(
      io: StringIO.new(zip_content),
      filename:,
      content_type: 'application/zip'
    )

    context.documents_package = market_application.documents_package
  end

  def filename
    "documents_package_FT#{market_application.identifier}.zip"
  end

  def generate_zip_content
    zip_buffer = Zip::OutputStream.write_buffer do |zip|
      add_attestation_to_zip(zip)
      add_uploaded_documents_to_zip(zip)
    end

    zip_buffer.string
  end

  def add_attestation_to_zip(zip)
    attestation_filename = "attestation_FT#{market_application.identifier}.pdf"
    attestation_content = market_application.attestation.download

    zip.put_next_entry(attestation_filename)
    zip.write(attestation_content)
  end

  def add_uploaded_documents_to_zip(zip)
    file_uploads = load_file_uploads
    return if file_uploads.empty?

    file_uploads.each_with_index do |upload, index|
      add_single_document_to_zip(zip, upload, index)
    end
  end

  def load_file_uploads
    market_application.market_attribute_responses
      .where(type: 'FileUpload')
      .includes(:market_attribute, document_attachment: :blob)
  end

  def add_single_document_to_zip(zip, upload, index)
    return unless upload.document.attached?

    field_key = upload.market_attribute.key
    original_filename = upload.document.filename.to_s
    zip_filename = "documents/#{format('%02d', index + 1)}_#{field_key}_#{original_filename}"

    zip.put_next_entry(zip_filename)
    zip.write(upload.document.download)
  rescue StandardError => e
    Rails.logger.error "Failed to add document to ZIP: #{e.message}"
    # Continue with other documents even if one fails
  end
end
