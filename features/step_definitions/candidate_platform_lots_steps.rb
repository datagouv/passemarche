# frozen_string_literal: true

PLATFORM_LOTS_SIRET = '73282932000074'

def post_platform_application(lot_ids: nil)
  header 'Authorization', "Bearer #{@previous_token}"
  header 'Content-Type', 'application/json'

  market_application_params = { siret: PLATFORM_LOTS_SIRET }
  market_application_params = market_application_params.merge(application_mode: 'solo', lot_ids:) unless lot_ids.nil?

  post "/api/v1/public_markets/#{@multi_public_market.identifier}/market_applications",
    { market_application: market_application_params }.to_json

  @response_status = last_response.status
  @response_body = JSON.parse(last_response.body)
  @market_application = MarketApplication.find_by(identifier: @response_body['identifier'])
end

def platform_lot_ids(*lot_names)
  lot_names.map { |name| @multi_public_market.lots.find_by!(name:).id }
end

Given('the multi-type market is published by the editor') do
  @multi_public_market.update!(editor: @editor, published_at: Time.current, sync_status: :sync_completed)
end

When('the platform creates an application with the lots {string}') do |lot_name|
  post_platform_application(lot_ids: platform_lot_ids(lot_name))
end

Given('the platform created an application with the lots {string}') do |lot_name|
  post_platform_application(lot_ids: platform_lot_ids(lot_name))
end

When('the platform creates an application with the lots {string} and {string}') do |first_lot_name, second_lot_name|
  post_platform_application(lot_ids: platform_lot_ids(first_lot_name, second_lot_name))
end

When('the platform creates an application with a lot of another market') do
  post_platform_application(lot_ids: [create(:lot).id])
end

When('the platform creates an application without lots') do
  post_platform_application
end

When('the candidate opens the application created by the platform') do
  authenticate_as_candidate_for(@market_application)
end

When('the candidate visits the lots recap') do
  visit lot_selection_candidate_market_application_path(@market_application.identifier)
end

Given('the candidate answered the INSEE question') do
  @insee_response = create(:market_attribute_response_text_input, market_application: @market_application,
    market_attribute: @insee_attribute, source: :manual, value: { 'text' => 'Acme Corp' })
end

Then('the candidate should see {int} transmitted lot(s) without being able to edit the lots') do |count|
  expect(page).to have_content("#{I18n.t('candidate.lot_selection.lots_list_title')} (#{count})")
  expect(page).to have_no_link(I18n.t('candidate.lot_selection.edit_lots'))
  expect(page).to have_no_field(type: :checkbox)
end

Then('the candidate should be told to change the lots on the platform') do
  expect(page).to have_content(I18n.t('shared.platform_lots_notices.locked'))
end

Then('the API should refuse the application because of the lots') do
  expect(@response_status).to eq(422)
  expect(@response_body.dig('errors', 'lot_ids')).to be_present
end

Then('no application should have been created') do
  expect(MarketApplication.where(public_market: @multi_public_market)).to be_empty
end

Then('the application should only declare the lot {string}') do |lot_name|
  expect(@market_application.reload.lots.map(&:name)).to eq([lot_name])
end

Then('the INSEE answer should be kept') do
  expect(MarketAttributeResponse.exists?(@insee_response.id)).to be true
end

Then('the candidate should be warned that the platform added a new lot type') do
  expect(page).to have_content(I18n.t('shared.platform_lots_notices.new_lot_types'))
end
