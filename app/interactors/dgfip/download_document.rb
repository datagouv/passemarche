# frozen_string_literal: true

class Dgfip::DownloadDocument < DownloadDocument
  include SiretHelpers

  protected

  def document_url_key
    :document
  end

  def generate_filename(_uri)
    "attestation_fiscale_#{siren}.pdf"
  end
end
