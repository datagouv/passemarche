# frozen_string_literal: true

class GenerateBuyerAttestationPdf < ApplicationInteractor
  include PdfGeneratable

  delegate :market_application, to: :context

  def call
    context.fail!(message: 'Attestation acheteur déjà générée') if market_application.buyer_attestation.attached?

    generate_and_attach_pdf(
      attachment: market_application.buyer_attestation,
      template: 'buyer/attestations/show',
      locals: { market_application:, transmission_time: },
      filename:
    )
    context.buyer_attestation = market_application.buyer_attestation
  end

  private

  def transmission_time
    @transmission_time ||= Time.zone.now.strftime('%d/%m/%Y à %H:%M')
  end

  def filename
    "buyer_attestation_FT#{market_application.identifier}.pdf"
  end

  def pdf_error_message
    "Failed to generate buyer attestation PDF for application #{market_application.identifier}"
  end

  def pdf_sentry_extra
    {
      market_application_id: market_application.id,
      market_application_identifier: market_application.identifier,
      siret: market_application.siret,
      public_market_id: market_application.public_market_id
    }
  end

  def pdf_error_stage
    'buyer_attestation_pdf_generation'
  end

  def pdf_document_type
    'buyer_attestation'
  end

  def pdf_failure_i18n_message
    I18n.t('errors.market_application.buyer_attestation_generation_failed')
  end
end
