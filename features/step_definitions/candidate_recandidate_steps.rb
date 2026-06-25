# frozen_string_literal: true

RECANDIDATE_SIRET = '73282932000074'

Given('un marché public ouvert existe avec des attributs') do
  @public_market = create(:public_market, :completed, editor: @editor, deadline: 1.month.from_now)

  @manual_attribute = create(:market_attribute, :text_input,
    key: 'recandidate_manual_field',
    category_key: 'test_identite_entreprise',
    subcategory_key: 'test_identite_entreprise_identification',
    public_markets: [@public_market])

  @api_attribute = create(:market_attribute, :text_input,
    key: 'recandidate_api_field',
    category_key: 'test_identite_entreprise',
    subcategory_key: 'test_identite_entreprise_identification',
    api_name: 'Insee',
    api_key: 'denomination',
    public_markets: [@public_market])
end

Given('une candidature complétée existe avec des données manuelles et API') do
  @market_application = create(:market_application, :completed,
    public_market: @public_market,
    siret: RECANDIDATE_SIRET,
    api_fetch_status: { 'Insee' => { 'status' => 'completed', 'fields_filled' => 1 } })

  @manual_response = create(:market_attribute_response_text_input,
    market_application: @market_application,
    market_attribute: @manual_attribute,
    source: :manual,
    value: { 'text' => 'Données saisies manuellement' })

  @api_response = create(:market_attribute_response_text_input,
    market_application: @market_application,
    market_attribute: @api_attribute,
    source: :auto,
    value: { 'text' => 'Données API INSEE' })
end

Given('la date limite du marché est dépassée') do
  @public_market.update!(deadline: 1.day.ago)
end

When('le profil acheteur crée une candidature pour le même SIRET') do
  token = @previous_token || @access_token
  header 'Authorization', "Bearer #{token}"
  header 'Content-Type', 'application/json'

  post "/api/v1/public_markets/#{@public_market.identifier}/market_applications",
    { market_application: { siret: RECANDIDATE_SIRET } }.to_json

  @response_status = last_response.status
  @response_body = JSON.parse(last_response.body) if last_response.body.present?
end

Then('la réponse API est un succès') do
  expect(@response_status).to be_in([200, 201])
end

Then('la candidature est remise à zéro') do
  @market_application.reload
  expect(@market_application.completed_at).to be_nil
  expect(@market_application).to be_sync_pending
  expect(@market_application.attests_no_exclusion_motifs).to be false
end

Then('les données manuelles sont conservées') do
  expect(MarketAttributeResponse.exists?(@manual_response.id)).to be true
  expect(@manual_response.reload.value).to eq({ 'text' => 'Données saisies manuellement' })
end

Then('les données API sont supprimées') do
  expect(MarketAttributeResponse.exists?(@api_response.id)).to be false
end

Then('le statut de récupération API est réinitialisé') do
  @market_application.reload
  expect(@market_application.api_fetch_status).to eq({})
end

Then('la candidature reste complétée') do
  @market_application.reload
  expect(@market_application).to be_completed
end
