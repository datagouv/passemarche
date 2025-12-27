# frozen_string_literal: true

require 'webmock/cucumber'

Given('a public market with ESS field exists') do
  @editor = create(:editor)
  @public_market = create(:public_market, :completed, editor: @editor)

  @ess_attribute = create(
    :market_attribute,
    key: 'capacites_techniques_professionnelles_certificats_ess',
    input_type: 'radio_with_file_and_text',
    api_name: 'insee',
    api_key: 'ess',
    category_key: 'capacites_techniques_professionnelles',
    subcategory_key: 'capacites_techniques_professionnelles_certificats'
  )
  @ess_attribute.public_markets << @public_market

  # Add contact attribute so we can pass through steps
  @contact_attribute = create(
    :market_attribute,
    key: 'identite_entreprise_contact_email',
    input_type: 'email_input',
    category_key: 'identite_entreprise',
    subcategory_key: 'identite_entreprise_contact'
  )
  @contact_attribute.public_markets << @public_market

  @contact_phone_attribute = create(
    :market_attribute,
    key: 'identite_entreprise_contact_telephone',
    input_type: 'phone_input',
    category_key: 'identite_entreprise',
    subcategory_key: 'identite_entreprise_contact'
  )
  @contact_phone_attribute.public_markets << @public_market
end

Given('the INSEE API returns ESS true') do
  stub_insee_api_with_ess(true)
  stub_other_apis_for_ess
end

Given('the INSEE API returns ESS false') do
  stub_insee_api_with_ess(false)
  stub_other_apis_for_ess
end

Given('the INSEE API returns ESS null') do
  stub_insee_api_with_ess(nil)
  stub_other_apis_for_ess
end

Given('the INSEE API returns an error') do
  stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v3/insee/sirene/etablissements/.*})
    .to_return(
      status: 503,
      body: { errors: [{ detail: 'Service temporarily unavailable' }] }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  stub_other_apis_for_ess
end

When('I start an application for the ESS market') do
  @market_application = create(
    :market_application,
    public_market: @public_market,
    siret: '41816609600069'
  )
end

When('all APIs complete for ESS') do
  FetchInseeDataJob.perform_now(@market_application.id)
  @market_application.reload
end

When('all APIs complete for ESS with failures') do
  FetchInseeDataJob.perform_now(@market_application.id)
  @market_application.reload
end

Then('the market application should have ESS data with radio_choice yes') do
  @market_application.reload
  ess_response = find_ess_response

  expect(ess_response).not_to be_nil
  expect(ess_response.radio_choice).to eq('yes')
  expect(ess_response.text).to include('ESS')
end

Then('the market application should have ESS data with radio_choice no') do
  @market_application.reload
  ess_response = find_ess_response

  expect(ess_response).not_to be_nil
  expect(ess_response.radio_choice).to eq('no')
end

Then('the ESS response should have source auto') do
  ess_response = find_ess_response

  expect(ess_response.source).to eq('auto')
end

Then('the market application should not have an ESS response') do
  @market_application.reload
  ess_response = find_ess_response

  # When ESS is null, no response is created (skip logic in MapInseeApiData)
  expect(ess_response).to be_nil
end

Then('the market application should have a manual fallback response for ESS') do
  @market_application.reload
  ess_response = find_ess_response

  # When API fails, a response is created with manual_after_api_failure source
  expect(ess_response).not_to be_nil
  expect(ess_response.source).to eq('manual_after_api_failure')
end

Then('the ESS field should allow manual input') do
  # When ESS is null or API fails, no response is created
  # This allows the candidate to fill it manually
  ess_response = find_ess_response

  # Either no response exists, or it's marked for manual input
  if ess_response.present?
    expect(ess_response.source).to eq('manual_after_api_failure')
  else
    expect(ess_response).to be_nil
  end
end

def find_ess_response
  @market_application.market_attribute_responses
    .joins(:market_attribute)
    .find_by(market_attributes: { api_key: 'ess' })
end

def stub_insee_api_with_ess(ess_value)
  response_body = build_insee_response_with_ess(ess_value)

  stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v3/insee/sirene/etablissements/.*})
    .to_return(
      status: 200,
      body: response_body,
      headers: { 'Content-Type' => 'application/json' }
    )
end

def build_insee_response_with_ess(ess_value)
  {
    data: {
      siret: '41816609600069',
      siege_social: true,
      etat_administratif: 'A',
      activite_principale: {
        code: '6202A',
        libelle: 'Conseil en systèmes et logiciels informatiques',
        nomenclature: 'NAFRev2'
      },
      unite_legale: {
        siren: '418166096',
        siret_siege_social: '41816609600069',
        type: 'personne_morale',
        personne_morale_attributs: {
          raison_sociale: 'OCTO TECHNOLOGY',
          sigle: 'OCTO'
        },
        categorie_entreprise: 'PME',
        economie_sociale_solidaire: ess_value
      }
    },
    meta: { date_derniere_mise_a_jour: 1_704_067_200 },
    links: {}
  }.to_json
end

def stub_other_apis_for_ess
  # Stub RNE API
  stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v3/inpi/rne/unites_legales/.*/extrait_rne})
    .to_return(
      status: 404,
      body: { errors: [] }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
end
