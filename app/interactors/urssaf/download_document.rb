# frozen_string_literal: true

class Urssaf::DownloadDocument < DownloadDocument
  include SiretHelpers

  protected

  def document_url_key
    :document
  end

  def generate_filename(_uri)
    "attestation_vigilance_urssaf_#{siret}.pdf"
  end
end
