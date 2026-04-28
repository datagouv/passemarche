# frozen_string_literal: true

Given('I create a public market with multiple lots') do
  public_market = create(:public_market, editor: @editor, name: 'Marché alloti de travaux')
  create(:lot, public_market:, name: 'Lot 1 - Gros œuvre et maçonnerie')
  create(:lot, public_market:, name: 'Lot 2 - Charpente et couverture')
  create(:lot, public_market:, name: 'Lot 3 - Électricité et équipements techniques')
  @market_identifier = public_market.identifier
end

When('I visit the lot_config page for my public market') do
  @market_identifier ||= @last_api_response['identifier']
  visit step_buyer_public_market_path(identifier: @market_identifier, id: :lot_config)
end

Then('I should be on the lot_config page') do
  @market_identifier ||= @last_api_response['identifier']
  expect(page).to have_current_path(step_buyer_public_market_path(@market_identifier, :lot_config))
end

When('I choose {string} for lot limit') do |choice|
  radio_value = choice == 'Oui' ? 'true' : 'false'
  find("input[name='lot_limit_enabled'][value='#{radio_value}']").click
end

When('I set the lot limit to {int}') do |limit|
  fill_in 'lot_limit', with: limit
end

When('I submit the lot_config form') do
  click_button I18n.t('buyer.public_markets.lot_config.submit')
end

Then('the public market should have no lot limit') do
  public_market = PublicMarket.find_by!(identifier: @market_identifier)
  expect(public_market.lot_limit).to be_nil
end

Then('the public market should have a lot limit of {int}') do |limit|
  public_market = PublicMarket.find_by!(identifier: @market_identifier)
  expect(public_market.lot_limit).to eq(limit)
end

Then('the lot limit section should not be visible') do
  expect(page).to have_no_text(I18n.t('buyer.summary.lot_limit'))
end

Given('the buyer lot config public market has a lot limit of {int}') do |limit|
  public_market = PublicMarket.find_by!(identifier: @market_identifier)
  public_market.update!(lot_limit: limit)
end
