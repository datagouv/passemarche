# frozen_string_literal: true

class Qualibat::MakeRequest < MakeRequest
  def endpoint_url
    "v4/qualibat/etablissements/#{siret}/certification_batiment"
  end

  private

  def siret
    context.params[:siret]
  end
end
