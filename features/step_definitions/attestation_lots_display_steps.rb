# frozen_string_literal: true

Given('a public market with lots exists for attestation') do
  @editor = create(:editor)
  @public_market = create(:public_market, :completed, editor: @editor, market_type_codes: ['works'])
  @lot1 = create(:lot, public_market: @public_market, name: 'Modèle de borne « lite »', position: 1)
  @lot2 = create(:lot, public_market: @public_market, name: 'Modèle de borne « mid »', position: 2)
end

Given('a candidate has selected lots for the attestation market') do
  @market_application = create(:market_application, public_market: @public_market, siret: '73282932000074')
  @market_application.lots << @lot1
  authenticate_as_candidate_for(@market_application)
end

Given('a candidate has selected two lots for the attestation market') do
  @market_application = create(:market_application, public_market: @public_market, siret: '73282932000074')
  @market_application.lots << [@lot1, @lot2]
  authenticate_as_candidate_for(@market_application)
end

Given('a candidate has selected only the first lot for the attestation market') do
  @market_application = create(:market_application, public_market: @public_market, siret: '73282932000074')
  @market_application.lots << @lot1
  authenticate_as_candidate_for(@market_application)
end

Given('a candidate applies to a market without lots') do
  @editor_no_lots = create(:editor)
  @public_market_no_lots = create(:public_market, :completed, editor: @editor_no_lots)
  @market_application_no_lots = create(:market_application,
    public_market: @public_market_no_lots,
    siret: '73282932000074')
  authenticate_as_candidate_for(@market_application_no_lots)
end

When('I visit the attestation summary page') do
  visit step_candidate_market_application_path(@market_application.identifier, 'summary')
end

When('I visit the non-alloti attestation summary page') do
  visit step_candidate_market_application_path(@market_application_no_lots.identifier, 'summary')
end

Then('the lots should appear in ascending order') do
  lot1_position = page.body.index('Lot 1')
  lot2_position = page.body.index('Lot 2')
  expect(lot1_position).to be < lot2_position
end
