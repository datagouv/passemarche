# frozen_string_literal: true

class Qualibat::DownloadDocument < DownloadDocument
  include SiretHelpers

  protected

  def document_url_key
    :document
  end

  def generate_filename(_uri)
    "certificat_qualibat_#{siren}.pdf"
  end
end
