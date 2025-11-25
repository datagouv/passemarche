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

  # rubocop:disable Metrics/AbcSize
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
        error_stage: 'documents_package_generation',
        error_class: error.class.name,
        error_message: error.message
      },
      tags: {
        component: 'zip_generation',
        document_type: 'documents_package'
      }
    )

    context.fail!(message: I18n.t('errors.market_application.documents_package_generation_failed'))
  end
  # rubocop:enable Metrics/AbcSize

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

  # rubocop:disable Metrics/AbcSize
  def add_documents_from_response_to_zip(zip, response, response_index)
    return unless response.documents.attached?

    response.documents.each_with_index do |document, doc_index|
      add_single_document_to_zip(zip, document, response, response_index, doc_index)
    end
  rescue StandardError => e
    Rails.logger.warn "Failed to add document to ZIP for response #{response.id}: #{e.message}"
    Sentry.capture_exception(
      e,
      level: :warning,
      extra: {
        market_application_id: market_application.id,
        market_application_identifier: market_application.identifier,
        response_id: response.id,
        market_attribute_key: response.market_attribute&.key
      },
      tags: {
        component: 'zip_generation',
        document_type: 'user_uploaded_document'
      }
    )
    # Continue with other documents even if one fails
  end
  # rubocop:enable Metrics/AbcSize

  def add_single_document_to_zip(zip, document, _response, _response_index, _doc_index)
    system_filename = naming_service.system_filename_for(document)
    zip_filename = "documents/#{system_filename}"

    zip.put_next_entry(zip_filename)
    zip.write(document.download)
  rescue StandardError => e
    Rails.logger.error "Failed to add document #{document.filename} to ZIP: #{e.message}"
  end

  def naming_service
    @naming_service ||= DocumentNamingService.new(market_application)
  end
end
