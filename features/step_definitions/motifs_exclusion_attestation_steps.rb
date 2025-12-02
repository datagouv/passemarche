# frozen_string_literal: true

Given('a public market with motifs_exclusion fields exists') do
  @editor = create(:editor)
  @public_market = create(:public_market, :completed, editor: @editor)

  create(:market_attribute,
    :text_input,
    key: 'test_motif_field',
    category_key: 'motifs_exclusion',
    subcategory_key: 'motifs_exclusion_fiscales_et_sociales',
    public_markets: [@public_market])
end

Given('a candidate application with attests_no_exclusion_motifs checked') do
  @market_application = create(:market_application,
    public_market: @public_market,
    siret: '73282932000074',
    attests_no_exclusion_motifs: true)

  market_attribute = @public_market.market_attributes.find_by(key: 'test_motif_field')
  create(:market_attribute_response_text_input,
    market_application: @market_application,
    market_attribute:,
    text: 'Test value',
    source: :manual)
end

Given('the candidate has not confirmed the exclusion motifs attestation') do
  @market_application.update!(attests_no_exclusion_motifs: false)
end

When('I visit the summary page for my application') do
  visit "/candidate/market_applications/#{@market_application.identifier}/summary"
end
