# frozen_string_literal: true

Given('a public market with optional motifs exclusion radio fields exists') do
  @public_market = create(:public_market, :completed, editor: @editor)

  @motifs_exclusion_attr = create(:market_attribute,
    key: 'motifs_exclusion_optional_test',
    mandatory: false,
    category_key: 'motifs_exclusion',
    subcategory_key: 'motifs_exclusion_appreciation_acheteur_discretionnaire',
    input_type: :radio_with_file_and_text,
    public_markets: [@public_market])
end

Given('a market application with motifs exclusion answered Oui') do
  @market_application = create(:market_application,
    public_market: @public_market,
    siret: '73282932000074',
    attests_no_exclusion_motifs: true)

  create(:market_attribute_response_radio_with_file_and_text,
    market_application: @market_application,
    market_attribute: @motifs_exclusion_attr,
    source: :manual,
    value: { 'radio_choice' => 'yes' })
end

Given('a market application with motifs exclusion answered Non') do
  @market_application = create(:market_application,
    public_market: @public_market,
    siret: '73282932000074',
    attests_no_exclusion_motifs: true)

  create(:market_attribute_response_radio_with_file_and_text,
    market_application: @market_application,
    market_attribute: @motifs_exclusion_attr,
    source: :manual,
    value: { 'radio_choice' => 'no' })
end

Then('I should see an error badge with text {string}') do |text|
  expect(page).to have_css('div.fr-badge.fr-badge--error', text:)
end

Then('I should see a success badge with text {string}') do |text|
  expect(page).to have_css('div.fr-badge.fr-badge--success', text:)
end
