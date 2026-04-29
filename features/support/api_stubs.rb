# frozen_string_literal: true

# Default stub for FetchPublicMarketBuyerNameJob triggered when markets are created inline.
# Specific scenarios override this with their own stubs as needed.
Before do
  stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v3/insee/sirene/etablissements/.*})
    .to_return(
      status: 200,
      body: {
        data: {
          unite_legale: {
            personne_morale_attributs: { raison_sociale: nil }
          }
        }
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
end
