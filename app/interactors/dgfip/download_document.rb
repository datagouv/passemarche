# frozen_string_literal: true

class Dgfip::DownloadDocument < DownloadDocument
  protected

  def document_url_key
    :document
  end

  def generate_filename(_uri)
    siren = context.params[:siret][0..8]
    "attestation_fiscale_#{siren}.pdf"
  end
end
