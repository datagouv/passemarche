# frozen_string_literal: true

class Qualibat::MakeRequest < MakeRequest
  def call
    validate_credentials
    super
  end

  def endpoint_url
    "v4/qualibat/etablissements/#{siret}/certification_batiment"
  end

  private

  def validate_credentials
    return if Rails.application.credentials.api_entreprise&.token.present?

    context.fail!(error: 'Missing API credentials')
  end

  def siret
    context.params[:siret]
  end
end
