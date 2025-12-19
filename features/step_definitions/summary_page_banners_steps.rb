# frozen_string_literal: true

Given('an editor exists') do
  @editor = create(:editor)
end

Given('a public market with optional market attributes exists') do
  @public_market = create(:public_market, :completed, editor: @editor)

  create(:market_attribute,
    key: 'mandatory_field',
    mandatory: true,
    category_key: 'identite_entreprise',
    subcategory_key: 'identification',
    public_markets: [@public_market])

  create(:market_attribute,
    key: 'optional_field',
    mandatory: false,
    category_key: 'identite_entreprise',
    subcategory_key: 'identification',
    public_markets: [@public_market])
end

Given('a public market with only mandatory market attributes exists') do
  @public_market = create(:public_market, :completed, editor: @editor)

  create(:market_attribute,
    key: 'mandatory_field_1',
    mandatory: true,
    category_key: 'identite_entreprise',
    subcategory_key: 'identification',
    public_markets: [@public_market])

  create(:market_attribute,
    key: 'mandatory_field_2',
    mandatory: true,
    category_key: 'identite_entreprise',
    subcategory_key: 'identification',
    public_markets: [@public_market])
end

Given('a market application exists for this market') do
  @market_application = create(:market_application,
    public_market: @public_market,
    siret: '73282932000074')
end

When('I visit the candidate summary page') do
  visit "/candidate/market_applications/#{@market_application.identifier}/summary"
end

Then('I should see the buyer additional info banner') do
  expect(page).to have_content(
    I18n.t('candidate.market_applications.summary.buyer_additional_info_banner')
  )
end

Then('I should not see the buyer additional info banner') do
  expect(page).not_to have_content(
    I18n.t('candidate.market_applications.summary.buyer_additional_info_banner')
  )
end

Given('a public market with motifs exclusion attributes exists') do
  @public_market = create(:public_market, :completed, editor: @editor)

  create(:market_attribute,
    key: 'motifs_exclusion_field',
    mandatory: true,
    category_key: 'motifs_exclusion',
    subcategory_key: 'motifs_exclusion_fiscales',
    public_markets: [@public_market])
end

Given('a market application exists with attestation not confirmed') do
  @market_application = create(:market_application,
    public_market: @public_market,
    siret: '73282932000074',
    attests_no_exclusion_motifs: false)
end

Given('a market application exists with attestation confirmed') do
  @market_application = create(:market_application,
    public_market: @public_market,
    siret: '73282932000074',
    attests_no_exclusion_motifs: true)
end

Then('I should see the exclusion motifs warning banner') do
  expect(page).to have_content(
    I18n.t('buyer.attestations.motifs_exclusion.candidate_attestation_not_confirmed_notice')
  )
end

Then('I should not see the exclusion motifs warning banner') do
  expect(page).not_to have_content(
    I18n.t('buyer.attestations.motifs_exclusion.candidate_attestation_not_confirmed_notice')
  )
end
