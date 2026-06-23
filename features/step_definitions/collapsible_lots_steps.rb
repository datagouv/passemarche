# frozen_string_literal: true

Given('I create a public market with many lots') do
  public_market = create(:public_market, editor: @editor, name: 'Marché gros volume')
  15.times do |i|
    create(:lot, public_market:, name: "Lot #{i + 1} - Description du lot #{i + 1}", position: i + 1)
  end
  @market_identifier = public_market.identifier
end

Then('the lots list should have the collapsible-list controller') do
  expect(page).to have_css('[data-controller~="collapsible-list"]')
  expect(page).to have_css('[data-collapsible-list-target="toggle"]', visible: :all)
end

Then('the lots table should have the collapsible-rows controller') do
  expect(page).to have_css('[data-controller~="collapsible-rows"]')
end

Then('the lots sidebar should have the collapsible-list controller') do
  expect(page).to have_css('[data-controller~="collapsible-list"]')
  expect(page).to have_css('[data-collapsible-list-target="toggle"]', visible: :all)
end
