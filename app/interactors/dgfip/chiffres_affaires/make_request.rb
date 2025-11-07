# frozen_string_literal: true

class Dgfip::ChiffresAffaires::MakeRequest < MakeRequest
  include SiretHelpers

  def endpoint_url
    "v3/dgfip/etablissements/#{siret}/chiffres_affaires"
  end
end
