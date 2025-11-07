# frozen_string_literal: true

class Cibtp::DownloadDocument < DownloadDocument
  protected

  def document_url_key
    :cibtp_document
  end

  def generate_filename(_uri)
    siret = context.params[:siret]
    "attestation_cibtp_#{siret}.pdf"
  end
end
