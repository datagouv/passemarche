# frozen_string_literal: true

class Qualibat::DownloadDocument < DownloadDocument
  def call
    validate_api_credentials
    return if context.failure?

    super
  end

  protected

  def document_url_key
    :document_url
  end

  def add_request_headers(request)
    token = Rails.application.credentials.api_entreprise&.token
    request['Authorization'] = "Bearer #{token}" if token.present?
    request['Accept'] = 'application/pdf, application/octet-stream, */*'
  end

  def generate_filename(_uri)
    siret = context.params[:siret]
    siren = siret[0..8]
    "certificat_qualibat_#{siren}.pdf"
  end

  private

  def validate_api_credentials
    return if Rails.application.credentials.api_entreprise&.token.present?

    context.fail!(error: 'Missing API credentials')
  end
end
