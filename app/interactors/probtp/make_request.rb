# frozen_string_literal: true

class Probtp::MakeRequest < MakeRequest
  include SiretHelpers

  def endpoint_url
    "v3/probtp/etablissements/#{siret}/attestation_cotisations_retraite"
  end
end
