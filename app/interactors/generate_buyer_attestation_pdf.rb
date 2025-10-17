# frozen_string_literal: true

class GenerateBuyerAttestationPdf < ApplicationInteractor
  delegate :market_application, to: :context

  def call
    context.fail!(message: 'Attestation acheteur déjà générée') if market_application.buyer_attestation.attached?

    generate_and_attach_pdf
    context.buyer_attestation = market_application.buyer_attestation
  end

  private

  # rubocop:disable Metrics/AbcSize
  def generate_and_attach_pdf
    ActiveRecord::Base.transaction do
      pdf_content = generate_pdf_content

      market_application.buyer_attestation.attach(
        io: StringIO.new(pdf_content),
        filename:,
        content_type: 'application/pdf'
      )
    end
  rescue ActiveStorage::Error => e
    context.fail!(message: "Erreur de stockage du fichier: #{e.message}")
  rescue ActiveRecord::ActiveRecordError => e
    context.fail!(message: "Erreur de base de données lors de l'attachement: #{e.message}")
  rescue StandardError => e
    context.fail!(message: "Erreur inattendue lors de la génération de l'attestation acheteur #{market_application.identifier}: #{e.message}")
  end
  # rubocop:enable Metrics/AbcSize

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
