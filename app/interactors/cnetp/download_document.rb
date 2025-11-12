# frozen_string_literal: true

class Cnetp::DownloadDocument < DownloadDocument
  protected

  def document_url_key
    :cnetp_document
  end

  def generate_filename(_uri)
    siren = context.params[:siren]
    "attestation_cnetp_#{siren}.pdf"
  end
end
