# frozen_string_literal: true

class FetchBuyerName::MakeRequest < MakeRequest
  def call
    validate_credentials
    super
  end

  def endpoint_url
    "v3/insee/sirene/etablissements/#{context.public_market.siret}"
  end

  private

  def validate_credentials
    return if Rails.application.credentials.api_entreprise&.token.present?

    context.fail!(error: 'Missing API credentials')
  end

  def request_recipient
    context.public_market.siret
  end

  def request_object
    "Configuration marché: #{context.public_market.name}"
  end
end
