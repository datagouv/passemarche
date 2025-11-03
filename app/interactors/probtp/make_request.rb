# frozen_string_literal: true

class Probtp::MakeRequest < MakeRequest
  def endpoint_url
    "v3/probtp/etablissements/#{siret}/attestation_cotisations_retraite"
  end

  private

  def siret
    context.params[:siret]
  end
end
