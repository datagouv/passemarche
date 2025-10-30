# frozen_string_literal: true

class Dgfip::MakeRequest < MakeRequest
  def endpoint_url
    "v4/dgfip/unites_legales/#{siren}/attestation_fiscale"
  end

  private

  def siren
    context.params[:siret][0..8]
  end
end
