# frozen_string_literal: true

Given('a public market with motifs_exclusion fields exists') do
  @editor = create(:editor)
  @public_market = create(:public_market, :completed, editor: @editor)

  attr1 = MarketAttribute.find_or_create_by!(
    key: 'test_motif_field',
    category_key: 'motifs_exclusion',
    subcategory_key: 'motifs_exclusion_fiscales_et_sociales',
    input_type: MarketAttribute.input_types[:text_input]
  )
  attr1.public_markets << @public_market unless attr1.public_markets.include?(@public_market)
end

Given('a Bodacc exclusion motif exists for the candidate') do
  market_attribute = @public_market.market_attributes.find_or_create_by!(
    key: 'motifs_exclusion_fiscales_et_sociales_liquidation_judiciaire',
    category_key: 'motifs_exclusion',
    subcategory_key: 'motifs_exclusion_fiscales_et_sociales',
    api_name: 'bodacc',
    api_key: 'liquidation_judiciaire',
    input_type: MarketAttribute.input_types[:radio_with_file_and_text]
  )
  create(:market_attribute_response_file_or_textarea,
    market_application: @market_application,
    market_attribute:,
    source: :auto,
    hidden: true,
    value: { 'radio_choice' => 'yes' })
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
