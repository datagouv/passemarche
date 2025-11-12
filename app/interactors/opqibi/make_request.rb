# frozen_string_literal: true

class Opqibi::MakeRequest < MakeRequest
  def endpoint_url
    "v3/opqibi/unites_legales/#{siren}/certification_ingenierie"
  end

  private

  def siren
    context.params[:siret][0..8]
  end
end
