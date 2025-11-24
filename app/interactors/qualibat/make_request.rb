# frozen_string_literal: true

class Qualibat::MakeRequest < MakeRequest
  include SiretHelpers

  def endpoint_url
    "v4/qualibat/etablissements/#{siret}/certification_batiment"
  end
end
