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
    end

    zip_buffer.string
  end

  def add_attestation_to_zip(zip)
    attestation_filename = "attestation_FT#{market_application.identifier}.pdf"
    attestation_content = market_application.attestation.download

    zip.put_next_entry(attestation_filename)
    zip.write(attestation_content)
  end
end
