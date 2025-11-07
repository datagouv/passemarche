# frozen_string_literal: true

class Probtp::DownloadDocument < DownloadDocument
  include SiretHelpers

  protected

  def document_url_key
    :document
  end

  def generate_filename(_uri)
    "attestation_cotisations_retraite_probtp_#{siret}.pdf"
  end
end
