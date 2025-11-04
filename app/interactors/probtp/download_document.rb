# frozen_string_literal: true

class Probtp::DownloadDocument < DownloadDocument
  protected

  def document_url_key
    :document
  end

  def generate_filename(_uri)
    siret = context.params[:siret]
    "attestation_cotisations_retraite_probtp_#{siret}.pdf"
  end
end
