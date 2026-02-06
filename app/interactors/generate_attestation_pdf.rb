# frozen_string_literal: true

class GenerateAttestationPdf < ApplicationInteractor
  delegate :market_application, to: :context

  def call
    context.fail!(message: 'Attestation déjà générée') if market_application.attestation.attached?

    generate_and_attach_pdf
    context.attestation = market_application.attestation
  end

  private

  def generate_and_attach_pdf
    pdf_content = generate_pdf_content

    market_application.attestation.attach(
      io: StringIO.new(pdf_content),
      filename:,
      content_type: 'application/pdf'
    )
  rescue ActionView::Template::Error,
         ActionView::MissingTemplate,
         ActiveStorage::Error,
         Errno::ENOENT, Errno::EACCES,
         RuntimeError => e
    handle_error(e)
  end

  # rubocop:disable Metrics/AbcSize
  def handle_error(error)
    error_message = "Failed to generate attestation PDF for application #{market_application.identifier}"

    Rails.logger.error "#{error_message}: #{error.class} - #{error.message}"
    Rails.logger.error error.backtrace.first(10).join("\n")

    Sentry.capture_exception(
      error,
      extra: {
        market_application_id: market_application.id,
        market_application_identifier: market_application.identifier,
        siret: market_application.siret,
        public_market_id: market_application.public_market_id,
        error_stage: 'attestation_pdf_generation',
        error_class: error.class.name,
        error_message: error.message
      },
      tags: {
        component: 'pdf_generation',
        document_type: 'candidate_attestation'
      }
    )

    context.fail!(message: I18n.t('errors.market_application.attestation_generation_failed'))
  end
  # rubocop:enable Metrics/AbcSize

  def filename
    "attestation_FT#{market_application.identifier}.pdf"
  end

  def generate_pdf_content
    transmission_time = Time.zone.now.strftime('%d/%m/%Y à %H:%M')

    # Render main content HTML with inline header
    html_content = ApplicationController.render(
      template: 'candidate/attestations/show',
      formats: [:html],
      layout: false,
      locals: {
        market_application:,
        transmission_time:
      }
    )

    # Generate PDF with WickedPdf (wkhtmltopdf)
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
