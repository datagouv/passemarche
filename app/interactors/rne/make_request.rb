# frozen_string_literal: true

class Rne::MakeRequest < MakeRequest
  def call
    validate_credentials
    super
  end

  def endpoint_url
    "v3/inpi/rne/unites_legales/#{siren}/extrait_rne"
  end

  private

  def validate_credentials
    return if Rails.application.credentials.api_entreprise&.token.present?

    context.fail!(error: 'Missing API credentials')
  end

  def siren
    # Extract SIREN (first 9 digits) from SIRET (14 digits)
    context.params[:siret][0..8]
  end
end
