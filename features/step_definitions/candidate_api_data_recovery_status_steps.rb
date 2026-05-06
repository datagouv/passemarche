# frozen_string_literal: true

Given('un marché avec des attributs API exists') do
  @editor = create(:editor)
  @public_market = create(:public_market, :completed, editor: @editor)

  @insee_attribute = create(:market_attribute, :from_api, api_name: 'insee',
    category_key: 'identite_entreprise', subcategory_key: 'identite_entreprise_general')
  @rne_attribute = create(:market_attribute, :from_api, api_name: 'rne',
    category_key: 'identite_entreprise', subcategory_key: 'identite_entreprise_general')
  @attestations_attribute = create(:market_attribute, :from_api, api_name: 'attestations_fiscales',
    category_key: 'capacites_economiques', subcategory_key: 'capacites_economiques_attestations')

  [@insee_attribute, @rne_attribute, @attestations_attribute].each do |attr|
    attr.public_markets << @public_market
  end
end

Given('une candidature pour ce marché exists') do
  @market_application = create(:market_application, public_market: @public_market)
  authenticate_as_candidate_for(@market_application)
end

Given('les APIs sont en cours de récupération') do
  @market_application.update!(api_fetch_status: {
    'insee' => { 'status' => 'processing', 'fields_filled' => 0 },
    'rne' => { 'status' => 'pending', 'fields_filled' => 0 },
    'attestations_fiscales' => { 'status' => 'pending', 'fields_filled' => 0 }
  })
end

Given('toutes les APIs ont été récupérées avec succès') do
  @market_application.update!(api_fetch_status: {
    'insee' => { 'status' => 'completed', 'fields_filled' => 5 },
    'rne' => { 'status' => 'completed', 'fields_filled' => 3 },
    'attestations_fiscales' => { 'status' => 'completed', 'fields_filled' => 2 }
  })
end

Given('certaines APIs ont échoué') do
  @market_application.update!(api_fetch_status: {
    'insee' => { 'status' => 'completed', 'fields_filled' => 5 },
    'rne' => { 'status' => 'failed', 'fields_filled' => 0 },
    'attestations_fiscales' => { 'status' => 'completed', 'fields_filled' => 2 }
  })
end

When('je visite la page de récupération des données API') do
  visit step_candidate_market_application_path(@market_application.identifier, :api_data_recovery_status)
end

Then('je vois le bloc {string}') do |block_name|
  expect(page).to have_content(block_name)
end

Then('le bouton {string} est désactivé') do |button_label|
  expect(page).to have_button(button_label, disabled: true)
end

Then('le bouton {string} est activé') do |button_label|
  expect(page).to have_button(button_label, disabled: false)
end
