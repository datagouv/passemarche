# frozen_string_literal: true

class Qualibat::DownloadDocument < DownloadDocument
  protected

  def document_url_key
    :document
  end

  def generate_filename(_uri)
    siret = context.params[:siret]
    siren = siret[0..8]
    "certificat_qualibat_#{siren}.pdf"
  end
end
