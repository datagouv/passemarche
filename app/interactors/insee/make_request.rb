# frozen_string_literal: true

class Insee::MakeRequest < MakeRequest
  include SiretHelpers

  def call
    validate_credentials
    super
  end

  def endpoint_url
    "v3/insee/sirene/etablissements/#{siret}"
  end

  private

  def validate_credentials
    return if Rails.application.credentials.api_entreprise&.token.present?

    context.fail!(error: 'Missing API credentials')
  end
end
