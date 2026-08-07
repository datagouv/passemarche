# frozen_string_literal: true

Given('a {string} market type exists with mandatory fields') do |market_type_code|
  @market_type = MarketType.find_or_create_by!(code: market_type_code)
  @mandatory_field = FactoryBot.create(:market_attribute, :mandatory,
    key: 'mandatory_test_field',
    category_key: 'identite_entreprise')
  @market_type.market_attributes << @mandatory_field unless @market_type.market_attributes.include?(@mandatory_field)
end

Given('a completed but non-published market exists for the current editor') do
  @completed_market = FactoryBot.create(:public_market, :completed,
    editor: @editor,
    market_type_codes: [@market_type.code])
end

Given('a non-completed market exists for the current editor') do
  @non_completed_market = FactoryBot.create(:public_market,
    editor: @editor,
    market_type_codes: [@market_type.code])
end

Given('a published market exists for the current editor') do
  @published_market = FactoryBot.create(:public_market, :published,
    editor: @editor,
    market_type_codes: [@market_type.code])
end

Given('this market has an optional field in the {string} category') do |category_key|
  optional_field = FactoryBot.create(:market_attribute, key: 'optional_test_field', category_key:)
  @market_type.market_attributes << optional_field unless @market_type.market_attributes.include?(optional_field)
end

When('I visit the setup page for the completed market') do
  visit step_buyer_public_market_path(identifier: @completed_market.identifier, id: :setup)
end

When('I visit the category page with optional fields for the completed market') do
  visit step_buyer_public_market_path(identifier: @completed_market.identifier, id: 'identite_entreprise')
end

When('I visit the category page with optional fields for the non-completed market') do
  visit step_buyer_public_market_path(identifier: @non_completed_market.identifier, id: 'identite_entreprise')
end

When('I visit the category page with optional fields for the non-completed market again') do
  click_link I18n.t('buyer.public_markets.navigation.previous')
end

When('I choose {string} and submit') do |option_label|
  click_button I18n.t('buyer.setup.rc_notice.close') if page.has_button?(I18n.t('buyer.setup.rc_notice.close'), wait: 1)
  find(:label, option_label, visible: :all).click
  click_button I18n.t('buyer.public_markets.navigation.next')
end

When('I visit the summary page for the completed market') do
  visit step_buyer_public_market_path(identifier: @completed_market.identifier, id: :summary)
end

When('I submit the summary step') do
  @original_completed_at = @completed_market.completed_at
  click_button I18n.t('buyer.summary.finalize')
end

When('I visit the setup page for the published market') do
  visit step_buyer_public_market_path(identifier: @published_market.identifier, id: :setup)
end

Then('I should see the setup page content') do
  expect(page).to have_content(@completed_market.name)
end

Then('the market should have a new completed_at timestamp') do
  @completed_market.reload
  expect(@completed_market.completed_at).to be > @original_completed_at
end

Then('the market sync status should be reset') do
  @completed_market.reload
  expect(@completed_market.sync_status).not_to eq('sync_completed')
end

Then('I should be redirected to the published page') do
  expect(page).to have_current_path(buyer_published_path(@published_market.identifier))
end

Then('I should see the published market message') do
  expect(page).to have_content(I18n.t('buyer.published.heading'))
end

Then('the {string} option should be selected') do |option_label|
  expect(page).to have_checked_field(option_label, visible: :all)
end

Then('I should see an enabled button {string}') do |button_text|
  expect(page).to have_button(button_text, exact: false, disabled: false)
end
