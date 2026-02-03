# frozen_string_literal: true

class ActesBilans::MakeRequest < MakeRequest
  include SiretHelpers

  def call
    validate_credentials
    super
  end

  def endpoint_url
    "v3/inpi/rne/unites_legales/open_data/#{siren}/actes_bilans"
  end

  private

  def validate_credentials
    return if Rails.application.credentials.api_entreprise&.token.present?

    context.fail!(error: 'Missing API credentials')
  end
end
