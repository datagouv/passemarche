# frozen_string_literal: true

class Fntp::MakeRequest < MakeRequest
  def endpoint_url
    "v3/fntp/unites_legales/#{siren}/carte_professionnelle_travaux_publics"
  end

  private

  def siren
    context.params[:siret][0..8]
  end
end
