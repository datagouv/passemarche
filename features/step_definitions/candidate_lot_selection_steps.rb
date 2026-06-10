# frozen_string_literal: true

Given('a public market with lots exists') do
  @lot1, @lot2 = setup_market_with_lots('Lot 1 - Fournitures', 'Lot 2 - Services')
end

Given('a candidate starts a new application for a market with lots') do
  start_candidate_application
end

Given('a public market without lots exists') do
  @editor_no_lots = create(:editor)
  @public_market_no_lots = FactoryBot.create(:public_market, :completed, editor: @editor_no_lots)
end

Given('a candidate starts a new application for a market without lots') do
  @market_application_no_lots = create(:market_application, public_market: @public_market_no_lots, siret: '73282932000074')
  authenticate_as_candidate_for(@market_application_no_lots)
end

Given('the public market has a lot limit of {int}') do |limit|
  @public_market.update!(lot_limit: limit)
end

Given('the candidate has already started the form') do
  @market_application = create(:market_application, public_market: @public_market, siret: '73282932000074')
  @market_application.lots << @lot1
  attr = @public_market.market_attributes.first
  create(:market_attribute_response_text_input,
    market_application: @market_application,
    market_attribute: attr,
    value: { text: 'Acme Corp' })
  authenticate_as_candidate_for(@market_application)
end

When('the candidate visits the lot selection step') do
  application = @market_application_no_lots || @market_application
  visit lot_selection_candidate_market_application_path(application.identifier)
end

When('the candidate visits the preparation page') do
  visit lot_selection_candidate_market_application_path(@market_application.identifier)
end

Then('the candidate should be on the lot selection step') do
  expect(page).to have_current_path(
    %r{/candidate/market_applications/.+/lots},
    ignore_query: true
  )
end

Then('the candidate should be on the api data recovery status step') do
  expect(page).to have_current_path(
    %r{/candidate/market_applications/.+/api_data_recovery_status},
    ignore_query: true
  )
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

When('the candidate clicks Suivant') do
  find('button[type="submit"][form="lot-selection-form"]').click
end

When('the candidate submits the lot selection step without selecting any lot') do
  find('button[type="submit"][form="lot-selection-form"]', visible: :all).click
end

Then('the candidate should see the preparation page') do
  expect(page).to have_content(I18n.t('candidate.lot_selection.prepare_title'))
end

Then('the candidate should see the complete button') do
  expect(page).to have_content(I18n.t('candidate.lot_selection.start'))
end

Then('the candidate should see the modify button') do
  expect(page).to have_content(I18n.t('candidate.lot_selection.modify'))
end

Then('the candidate should see the how it works section') do
  expect(page).to have_content(I18n.t('candidate.lot_selection.how_it_works_title'))
end

When('the candidate clicks the edit lots button') do
  click_on I18n.t('candidate.lot_selection.edit_lots')
end

Then('the candidate should be on the company identification step') do
  expect(page).to have_current_path(
    %r{/candidate/market_applications/.+/company_identification},
    ignore_query: true
  )
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

Then('the candidate should remain on the lot selection step') do
  expect(page).to have_current_path(
    %r{/candidate/market_applications/.+/lots},
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

Given('a multi-type public market with lots exists') do
  works_type    = MarketType.find_or_create_by!(code: 'works')
  services_type = MarketType.find_or_create_by!(code: 'services')

  @editor = create(:editor)
  @multi_public_market = create(:public_market, :completed, editor: @editor,
    name: 'Marché hétérogène travaux et services')
  @multi_public_market.market_type_codes = %w[works services]
  @multi_public_market.save!

  @lot_works1    = create(:lot, public_market: @multi_public_market, name: 'Lot 1 - Gros œuvre',
    market_type: works_type)
  @lot_works2    = create(:lot, public_market: @multi_public_market, name: 'Lot 2 - Charpente',
    market_type: works_type)
  @lot_services1 = create(:lot, public_market: @multi_public_market, name: 'Lot 3 - Prestations SI',
    market_type: services_type)
end

Given('a candidate starts a new application for the multi-type market') do
  @market_application = create(:market_application, public_market: @multi_public_market,
    siret: '73282932000074')
  authenticate_as_candidate_for(@market_application)
end

Then('they should see lots grouped by type') do
  expect(page).to have_content(I18n.t('market_types.works'))
  expect(page).to have_content(I18n.t('market_types.services'))
  works_index = page.body.index(I18n.t('market_types.works'))
  services_index = page.body.index(I18n.t('market_types.services'))
  lot1_index   = page.body.index('Lot 1 - Gros œuvre')
  lot3_index   = page.body.index('Lot 3 - Prestations SI')
  expect(lot1_index).to be > works_index
  expect(lot3_index).to be > services_index
end

When('the candidate selects one lot of each type') do
  check 'Lot 1 - Gros œuvre'
  check 'Lot 3 - Prestations SI'
end

Then('the preparation page should show the selected lot type tags') do
  expect(page).to have_css('.market-type-badge', text: I18n.t('market_types.works'))
  expect(page).to have_css('.market-type-badge', text: I18n.t('market_types.services'))
end
