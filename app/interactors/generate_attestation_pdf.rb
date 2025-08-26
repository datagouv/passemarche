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
    ActiveRecord::Base.transaction do
      pdf_content = generate_pdf_content

      market_application.attestation.attach(
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
    context.fail!(message: "Erreur inattendue lors de la génération de l'attestation: #{e.message}")
  end

  def filename
    "attestation_FT#{market_application.identifier}.pdf"
  end

  def generate_pdf_content
    html_content = ApplicationController.render(
      template: 'candidate/attestations/show',
      formats: [:pdf],
      layout: false,
      locals: { market_application: }
    )

    WickedPdf.new.pdf_from_string(
      html_content,
      page_size: 'A4',
      margin: {
        top: 20,
        bottom: 20,
        left: 15,
        right: 15
      }
    )
  end
end
