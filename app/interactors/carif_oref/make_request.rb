# frozen_string_literal: true

class CarifOref::MakeRequest < MakeRequest
  def endpoint_url
    "v3/carif_oref/etablissements/#{siret}/certifications_qualiopi_france_competences"
  end

  private

  def siret
    context.params[:siret]
  end
end
