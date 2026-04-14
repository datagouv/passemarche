# frozen_string_literal: true

def create_public_market_with_company_name_attribute(editor)
  public_market = create(:public_market, :completed, editor:)
  attr = MarketAttribute.find_or_create_by(key: 'company_name') do |a|
    a.category_key = 'identite_entreprise'
    a.subcategory_key = 'market_information'
    a.input_type = :text_input
    a.mandatory = false
  end
  public_market.market_attributes << attr
  public_market
end

Given('a public market with lots exists') do
  @editor = create(:editor)
  @public_market = create_public_market_with_company_name_attribute(@editor)
  @lot1 = create(:lot, public_market: @public_market, name: 'Lot 1 - Fournitures')
  @lot2 = create(:lot, public_market: @public_market, name: 'Lot 2 - Services')
end

Given('a candidate starts a new application for a market with lots') do
  @market_application = create(:market_application, public_market: @public_market, siret: '73282932000074')
  authenticate_as_candidate_for(@market_application)
end

Given('a public market without lots exists') do
  @editor_no_lots = create(:editor)
  @public_market_no_lots = create_public_market_with_company_name_attribute(@editor_no_lots)
end

Given('a candidate starts a new application for a market without lots') do
  @market_application_no_lots = create(:market_application,
    public_market: @public_market_no_lots,
    siret: '73282932000074')
  authenticate_as_candidate_for(@market_application_no_lots)
end

Given('the public market has a lot limit of {int}') do |limit|
  @public_market.update!(lot_limit: limit)
end

Then('they should see the lot selection page') do
  expect(page).to have_content(I18n.t('candidate.lot_selection.title'))
end

Then('they should see a checkbox for each lot') do
  expect(page).to have_field('Lot 1 - Fournitures', type: :checkbox)
  expect(page).to have_field('Lot 2 - Services', type: :checkbox)
end

When('the candidate selects the first lot') do
  check 'Lot 1 - Fournitures'
end

When('the candidate selects all available lots') do
  check 'Lot 1 - Fournitures'
  check 'Lot 2 - Services'
end

When('the candidate submits the lot selection form') do
  find('button[type="submit"]', visible: true).click
end

When('the candidate submits the lot selection form without selecting any lot') do
  find('button[type="submit"]', visible: true).click
end

Then('the candidate should be on the company identification step') do
  expect(page).to have_current_path(
    %r{/candidate/market_applications/.+/company_identification},
    ignore_query: true
  )
end

Then('the candidate should be on the summary step') do
  expect(page).to have_current_path(
    %r{/candidate/market_applications/.+/summary},
    ignore_query: true
  )
end

Then('the selected lots should be saved') do
  @market_application.reload
  expect(@market_application.lots).to include(@lot1)
end

Then('the candidate should see an error about selecting at least one lot') do
  expect(page).to have_content(
    I18n.t('activemodel.errors.models.lot_selection_policy.attributes.base.no_lot_selected')
  )
end

Then('the candidate should see an error about the lot limit') do
  expect(page).to have_content(
    I18n.t('activemodel.errors.models.lot_selection_policy.attributes.base.lot_limit_exceeded', limit: 1, count: 2)
  )
end

Then('the candidate should remain on the lot selection page') do
  expect(page).to have_current_path(
    "/candidate/market_applications/#{@market_application.identifier}/lots",
    ignore_query: true
  )
end

When('the candidate reconnects to the application') do
  @market_application.reload
  user = @market_application.user
  user.update!(authentication_token_sent_at: Time.current)
  token = user.generate_token_for(:magic_link)
  visit verify_candidate_sessions_path(token:, market_application_id: @market_application.identifier)
end

Given('the candidate has filled all fields') do
  attr = @public_market.market_attributes.first
  MarketAttributeResponse::TextInput.create!(
    market_application: @market_application,
    market_attribute: attr,
    value: { text: 'filled value' }
  )
end

Given('the candidate revisits the lot selection page') do
  visit lot_selection_candidate_market_application_path(@market_application.identifier)
end

Then('the candidate should see the field counter showing {string}') do |counter_text|
  expect(page).to have_css('p', text: counter_text, visible: false)
end

Then('the candidate should see the field counter in green') do
  expect(page).to have_css('[style*="text-default-success"]', visible: false)
end

Then('the progress card CTA should show {string}') do |cta_text|
  expect(page).to have_link(cta_text, href: %r{/candidate/market_applications/.+/company_identification}, visible: :all)
end
