# frozen_string_literal: true

class FetchRaisonSociale::MakeRequest < MakeRequest
  delegate :siret, to: :context

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

  def request_recipient
    siret
  end

  def request_object
    context.request_object || 'Réponse appel offre'
  end
end
