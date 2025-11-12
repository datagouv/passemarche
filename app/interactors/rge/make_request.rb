# frozen_string_literal: true

class Rge::MakeRequest < MakeRequest
  def endpoint_url
    "v3/ademe/etablissements/#{siret}/certification_rge"
  end

  private

  def siret
    context.params[:siret]
  end
end
