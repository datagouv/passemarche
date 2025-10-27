# frozen_string_literal: true

class GenerateBuyerAttestationPdf < ApplicationInteractor
  delegate :market_application, to: :context

  def call
    context.fail!(message: 'Attestation acheteur déjà générée') if market_application.buyer_attestation.attached?

    generate_and_attach_pdf
    context.buyer_attestation = market_application.buyer_attestation
  end

  private

  def generate_and_attach_pdf
    pdf_content = generate_pdf_content

    market_application.buyer_attestation.attach(
      io: StringIO.new(pdf_content),
      filename:,
      content_type: 'application/pdf'
    )
  rescue StandardError => e
    handle_error(e)
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def handle_error(error)
    error_message = "Failed to generate buyer attestation PDF for application #{market_application.identifier}"

    Rails.logger.error "#{error_message}: #{error.class} - #{error.message}"
    Rails.logger.error error.backtrace.first(10).join("\n")

    Sentry.capture_exception(
      error,
      extra: {
        market_application_id: market_application.id,
        market_application_identifier: market_application.identifier,
        siret: market_application.siret,
        public_market_id: market_application.public_market_id,
        error_stage: 'buyer_attestation_pdf_generation'
      },
      tags: {
        component: 'pdf_generation',
        document_type: 'buyer_attestation'
      }
    )

    user_message = case error
                   when ActiveStorage::Error
                     "Erreur de stockage du fichier acheteur: #{error.message}"
                   when ActiveRecord::ActiveRecordError
                     "Erreur de base de données lors de l'attachement de l'attestation acheteur: #{error.message}"
                   else
                     "Erreur inattendue lors de la génération de l'attestation acheteur: #{error.message}"
                   end

    context.fail!(message: user_message)
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def filename
    "buyer_attestation_FT#{market_application.identifier}.pdf"
  end

  def generate_pdf_content
    transmission_time = Time.zone.now.strftime('%d/%m/%Y à %H:%M')

    html_content = ApplicationController.render(
      template: 'buyer/attestations/show',
      formats: [:html],
      layout: false,
      locals: {
        market_application:,
        transmission_time:
      }
    )

    WickedPdf.new.pdf_from_string(
      html_content,
      page_size: 'A4',
      margin: {
        top: 20,
        bottom: 20,
        left: 15,
        right: 15
      },
      print_media_type: true
    )
  end
end
