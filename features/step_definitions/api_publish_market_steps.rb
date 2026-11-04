# frozen_string_literal: true

Given('a completed market exists for the current editor with identifier {string}') do |identifier|
  market_type = MarketType.find_or_create_by!(code: 'supplies')
  @existing_market = @editor.public_markets.create!(
    identifier:,
    name: 'Marché de test',
    deadline: 1.month.from_now,
    siret: '13002526500013',
    market_type_codes: [market_type.code],
    completed_at: Time.zone.now,
    sync_status: :sync_completed
  )
end

Given('a published market exists for the current editor with identifier {string}') do |identifier|
  market_type = MarketType.find_or_create_by!(code: 'supplies')
  @existing_market = @editor.public_markets.create!(
    identifier:,
    name: 'Marché de test publié',
    deadline: 1.month.from_now,
    siret: '13002526500013',
    market_type_codes: [market_type.code],
    completed_at: 1.day.ago,
    published_at: Time.zone.now,
    sync_status: :sync_completed
  )
end

When('I publish the market {string}') do |identifier|
  token = @access_token || @previous_token

  header 'Authorization', nil
  header 'Authorization', "Bearer #{token}" if token
  header 'Content-Type', 'application/json'

  post "/api/v1/public_markets/#{identifier}/publish"

  @response_status = last_response.status
  @response_body = JSON.parse(last_response.body) if last_response.body.present?
rescue JSON::ParserError
  @response_body = nil
end

Then('the market {string} should be published') do |identifier|
  market = PublicMarket.find_by!(identifier:)
  expect(market).to be_published
end

Then('the response should contain the error {string}') do |error_message|
  expect(@response_body['errors']['base']).to include(error_message)
end
