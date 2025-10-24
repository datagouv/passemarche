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
    context.fail!(message: 'Attestation acheteur requise pour créer le package') unless market_application.buyer_attestation.attached?
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
    attestation_filename = "buyer_attestation_FT#{market_application.identifier}.pdf"
    attestation_content = market_application.buyer_attestation.download

    zip.put_next_entry(attestation_filename)
    zip.write(attestation_content)
  end

  def add_uploaded_documents_to_zip(zip)
    responses = load_file_attachable_responses
    return if responses.empty?

    responses.each_with_index do |response, index|
      add_documents_from_response_to_zip(zip, response, index)
    end
  end

  def load_file_attachable_responses
    market_application.market_attribute_responses
      .with_file_attachments
      .includes(:market_attribute, documents_attachments: :blob)
      .order(:id)
  end

  def add_documents_from_response_to_zip(zip, response, response_index)
    return unless response.documents.attached?

    response.documents.each_with_index do |document, doc_index|
      add_single_document_to_zip(zip, document, response, response_index, doc_index)
    end
  rescue StandardError => e
    Rails.logger.error "Failed to add documents from response #{response.id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    # Continue with other documents even if one fails
  end

  def add_single_document_to_zip(zip, document, response, response_index, doc_index)
    field_key = response.market_attribute.key
    original_filename = document.filename.to_s
    zip_filename = build_zip_filename(response_index, doc_index, field_key, original_filename)

    zip.put_next_entry(zip_filename)
    zip.write(document.download)
  rescue StandardError => e
    Rails.logger.error "Failed to add document #{original_filename} to ZIP: #{e.message}"
    # Continue processing other documents
  end

  def build_zip_filename(upload_index, doc_index, field_key, original_filename)
    "documents/#{format('%02d', upload_index + 1)}_#{format('%02d', doc_index + 1)}_#{field_key}_#{original_filename}"
  end
end
