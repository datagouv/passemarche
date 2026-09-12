# frozen_string_literal: true

# Default stub for jobs hitting the Sirene "etablissements" endpoint (FetchPublicMarketBuyerNameJob,
# ResolveGroupingMemberCompanyNameJob), which run inline as soon as a market or a grouping member is created.
# Specific scenarios override this with their own stubs as needed.
Before do
  stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v3/insee/sirene/etablissements/.*})
    .to_return(
      status: 200,
      body: {
        data: {
          unite_legale: {
            personne_morale_attributs: { raison_sociale: 'Entreprise Test' }
          }
        }
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
end
