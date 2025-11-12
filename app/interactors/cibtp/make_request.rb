# frozen_string_literal: true

class Cibtp::MakeRequest < MakeRequest
  def endpoint_url
    "v3/cibtp/etablissements/#{siret}/attestation_cotisations_conges_payes_chomage_intemperies"
  end

  private

  def siret
    context.params[:siret]
  end
end
