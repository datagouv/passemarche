# frozen_string_literal: true

class Cnetp::MakeRequest < MakeRequest
  def endpoint_url
    "v3/cnetp/unites_legales/#{siren}/attestation_cotisations_conges_payes_chomage_intemperies"
  end

  private

  def siren
    context.params[:siren]
  end
end
