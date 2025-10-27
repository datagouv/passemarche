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
  rescue StandardError => e
    handle_error(e)
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def handle_error(error)
    error_message = "Failed to generate documents package for application #{market_application.identifier}"

    Rails.logger.error "#{error_message}: #{error.class} - #{error.message}"
    Rails.logger.error error.backtrace.first(10).join("\n")

    Sentry.capture_exception(
      error,
      extra: {
        market_application_id: market_application.id,
        market_application_identifier: market_application.identifier,
        siret: market_application.siret,
        public_market_id: market_application.public_market_id,
        error_stage: 'documents_package_generation'
      },
      tags: {
        component: 'zip_generation',
        document_type: 'documents_package'
      }
    )

    user_message = case error
                   when ActiveStorage::Error
                     "Erreur de stockage du package de documents: #{error.message}"
                   when ActiveRecord::ActiveRecordError
                     "Erreur de base de données lors de l'attachement du package: #{error.message}"
                   else
                     "Erreur inattendue lors de la génération du package de documents: #{error.message}"
                   end

    context.fail!(message: user_message)
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

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
    file_uploads = load_file_uploads
    return if file_uploads.empty?

    file_uploads.each_with_index do |upload, index|
      add_documents_from_upload_to_zip(zip, upload, index)
    end
  end

  def load_file_uploads
    market_application.market_attribute_responses
      .where(type: 'FileUpload')
      .includes(:market_attribute, documents_attachments: :blob)
  end

  # rubocop:disable Metrics/AbcSize
  def add_documents_from_upload_to_zip(zip, upload, index)
    return unless upload.documents.attached?

    upload.documents.each_with_index do |document, doc_index|
      add_single_document_to_zip(zip, document, upload, index, doc_index)
    end
  rescue StandardError => e
    Rails.logger.warn "Failed to add document to ZIP for upload #{upload.id}: #{e.message}"
    Sentry.capture_exception(
      e,
      level: :warning,
      extra: {
        market_application_id: market_application.id,
        market_application_identifier: market_application.identifier,
        upload_id: upload.id,
        market_attribute_key: upload.market_attribute&.key
      },
      tags: {
        component: 'zip_generation',
        document_type: 'user_uploaded_document'
      }
    )
    # Continue with other documents even if one fails
  end
  # rubocop:enable Metrics/AbcSize

  def add_single_document_to_zip(zip, document, upload, upload_index, doc_index)
    field_key = upload.market_attribute.key
    original_filename = document.filename.to_s
    zip_filename = build_zip_filename(upload_index, doc_index, field_key, original_filename)

    zip.put_next_entry(zip_filename)
    zip.write(document.download)
  end

  def build_zip_filename(upload_index, doc_index, field_key, original_filename)
    "documents/#{format('%02d', upload_index + 1)}_#{format('%02d', doc_index + 1)}_#{field_key}_#{original_filename}"
  end
end
