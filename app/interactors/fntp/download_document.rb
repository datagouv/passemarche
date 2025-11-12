# frozen_string_literal: true

class Fntp::DownloadDocument < DownloadDocument
  protected

  def document_url_key
    :document
  end

  def generate_filename(_uri)
    siren = context.params[:siret][0..8]
    "carte_professionnelle_tp_fntp_#{siren}.pdf"
  end
end
