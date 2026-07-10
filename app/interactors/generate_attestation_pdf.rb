# frozen_string_literal: true

class GenerateAttestationPdf < ApplicationInteractor
  include PdfGeneratable

  delegate :market_application, to: :context

  def call
    context.fail!(message: 'Attestation déjà générée') if market_application.attestation.attached?

    generate_and_attach_pdf(
      attachment: market_application.attestation,
      template: 'candidate/attestations/show',
      locals: { market_application:, transmission_time: },
      filename:
    )
    context.attestation = market_application.attestation
  end

  private

  def transmission_time
    @transmission_time ||= Time.zone.now.strftime('%d/%m/%Y à %H:%M')
  end

  def filename
    "attestation_FT#{market_application.identifier}.pdf"
  end

  def pdf_error_message
    "Failed to generate attestation PDF for application #{market_application.identifier}"
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
    'attestation_pdf_generation'
  end

  def pdf_document_type
    'candidate_attestation'
  end

  def pdf_failure_i18n_message
    I18n.t('errors.market_application.attestation_generation_failed')
  end
end
