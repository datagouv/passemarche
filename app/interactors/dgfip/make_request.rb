# frozen_string_literal: true

class Dgfip::MakeRequest < MakeRequest
  include SiretHelpers

  def endpoint_url
    "v4/dgfip/unites_legales/#{siren}/attestation_fiscale"
  end
end
