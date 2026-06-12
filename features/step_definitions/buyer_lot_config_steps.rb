# frozen_string_literal: true

Given('I create a public market with multiple lots') do
  public_market = create(:public_market, editor: @editor, name: 'Marché alloti de travaux')
  create(:lot, public_market:, name: 'Lot 1 - Gros œuvre et maçonnerie')
  create(:lot, public_market:, name: 'Lot 2 - Charpente et couverture')
  create(:lot, public_market:, name: 'Lot 3 - Électricité et équipements techniques')
  @market_identifier = public_market.identifier
end

Given('I create a public market with lots of multiple types') do
  public_market = create(:public_market, :multi_type, editor: @editor, name: 'Marché hétérogène travaux et services')
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

When('I visit the form_config page for my public market') do
  @market_identifier ||= @last_api_response['identifier']
  visit step_buyer_public_market_path(identifier: @market_identifier, id: :form_config)
end

Then('I should be on the form_config page') do
  @market_identifier ||= @last_api_response['identifier']
  expect(page).to have_current_path(step_buyer_public_market_path(@market_identifier, :form_config))
end

When('I click the edit lots button') do
  find("a[aria-label='#{I18n.t('buyer.public_markets.form_config.edit_lots_label')}']").click
end

Then('the type picker panel should be hidden') do
  expect(find('[data-lot-type-picker-target="panel"]', visible: false)).not_to be_visible
end

Then('the type picker panel should be visible') do
  expect(find('[data-lot-type-picker-target="panel"]', visible: false)).to be_visible
end

Then('the lot checkboxes should be hidden') do
  expect(first('[data-lot-type-picker-target="checkboxColumn"]', visible: false)).not_to be_visible
end

Then('the lot checkboxes should be visible') do
  expect(first('[data-lot-type-picker-target="checkboxColumn"]', visible: false)).to be_visible
end

Given('the lots have platform type {string}') do |code|
  market_type = MarketType.find_by!(code:)
  public_market = PublicMarket.find_by!(identifier: @market_identifier)
  public_market.lots.each { |lot| lot.update!(platform_market_type: market_type) }
end

When('I check the first lot checkbox') do
  first('input[data-action*="lot-type-picker#toggle"]').check
end

When('I select the type {string} in the type picker') do |label|
  within('[data-lot-type-picker-target="panel"]') do
    choose label
  end
end

Then('the first lot should have market type {string}') do |code|
  public_market = PublicMarket.find_by!(identifier: @market_identifier)
  first_lot = public_market.lots.ordered.first
  expect(page).to have_css("#lot_row_#{first_lot.id}")
  expect(first_lot.reload.market_type&.code).to eq(code)
end
