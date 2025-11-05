# frozen_string_literal: true

class Dgfip::ChiffresAffaires::MakeRequest < MakeRequest
  def endpoint_url
    "v3/dgfip/etablissements/#{siret}/chiffres_affaires"
  end

  private

  def siret
    context.params[:siret]
  end
end
