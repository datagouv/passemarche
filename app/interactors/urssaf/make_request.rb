# frozen_string_literal: true

class Urssaf::MakeRequest < MakeRequest
  include SiretHelpers

  def endpoint_url
    "v4/urssaf/unites_legales/#{siren}/attestation_vigilance"
  end
end
