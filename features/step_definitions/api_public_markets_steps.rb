# frozen_string_literal: true

Given('I do not have an access token') do
  @access_token = nil
  @previous_token = nil
end

Given('I have an invalid access token') do
  @access_token = 'invalid_token_12345'
end

When('I create a public market with the following details:') do |table|
  @public_market_params = table.rows_hash

  header 'Authorization', nil

  token = @access_token || @previous_token

  header 'Authorization', "Bearer #{token}" if token
  header 'Content-Type', 'application/json'

  post '/api/v1/public_markets', { public_market: @public_market_params }.to_json

  @response_status = last_response.status
  @response_body = JSON.parse(last_response.body) if last_response.body.present?
  @last_api_response = @response_body
rescue JSON::ParserError
  @response_body = nil
  @last_api_response = nil
end

When('I create another public market with the following details:') do |table|
  @previous_identifier = @response_body['identifier'] if @response_body

  step 'I create a public market with the following details:', table

  @second_response_body = @response_body
  @second_identifier = @response_body['identifier'] if @response_body
end

Then('I should receive a public market identifier starting with {string}') do |prefix|
  expect(@response_body).to have_key('identifier')
  expect(@response_body['identifier']).to start_with(prefix)
end

Then('I should receive a public market identifier') do
  expect(@response_body).to have_key('identifier')
  expect(@response_body['identifier']).to be_present
end

Then('I should receive a configuration URL') do
  expect(@response_body).to have_key('configuration_url')
  expect(@response_body['configuration_url']).to be_present
end

Then('the public market should be saved in the database') do
  identifier = @response_body['identifier']
  public_market = PublicMarket.find_by(identifier: identifier)

  expect(public_market).to be_present
  expect(public_market.market_name).to eq(@public_market_params['market_name'])
  expect(public_market.lot_name).to eq(@public_market_params['lot_name'])
  expect(public_market.deadline.iso8601).to eq(@public_market_params['deadline'])
  expect(public_market.market_type).to eq(@public_market_params['market_type'])
end

Then('the public market should have no lot name') do
  identifier = @response_body['identifier']
  public_market = PublicMarket.find_by(identifier: identifier)

  expect(public_market.lot_name).to be_nil
end

Then('I should receive an authentication error') do
  expect(@response_status).to eq(401)
end

Then('the error should include {string}') do |error_message|
  expect(@response_body).to have_key('errors')
  expect(@response_body['errors'].join(' ')).to include(error_message)
end

Then('the response should contain validation errors') do
  expect(@response_body).to have_key('errors')
  expect(@response_body['errors']).not_to be_empty
  errors_text = @response_body['errors'].join(' ')
  expect(errors_text).to match(/vide|blank|Translation missing/i)
end

Then('both public markets should be created successfully') do
  expect(@previous_identifier).to be_present
  expect(@second_identifier).to be_present

  first_market = PublicMarket.find_by(identifier: @previous_identifier)
  second_market = PublicMarket.find_by(identifier: @second_identifier)

  expect(first_market).to be_present
  expect(second_market).to be_present
end

Then('each public market should have a unique identifier') do
  expect(@previous_identifier).not_to eq(@second_identifier)
end

Then('both markets should belong to the same editor') do
  first_market = PublicMarket.find_by(identifier: @previous_identifier)
  second_market = PublicMarket.find_by(identifier: @second_identifier)

  expect(first_market.editor_id).to eq(second_market.editor_id)
  expect(first_market.editor_id).to eq(@editor.id)
end

Then('the identifier should match the format {string}') do |_format|
  identifier = @response_body['identifier']

  expect(identifier).to match(/^VR-\d{4}-[A-Z0-9]{12}$/)
end

Then('the year part should be the current year') do
  identifier = @response_body['identifier']
  year_part = identifier.split('-')[1]

  expect(year_part).to eq(Time.current.year.to_s)
end

Then('the suffix should be a 12-character alphanumeric code') do
  identifier = @response_body['identifier']
  code_part = identifier.split('-')[2]

  expect(code_part).to match(/^[A-Z0-9]{12}$/)
  expect(code_part.length).to eq(12)
end

Then('the configuration URL should contain the identifier') do
  identifier = @response_body['identifier']
  configuration_url = @response_body['configuration_url']

  expect(configuration_url).to include(identifier)
end

Then('the configuration URL should use the correct host') do
  configuration_url = @response_body['configuration_url']

  expect(configuration_url).to start_with('http://example.org')
end

Then('the configuration URL should point to the buyer configuration page') do
  identifier = @response_body['identifier']
  configuration_url = @response_body['configuration_url']

  expect(configuration_url).to end_with("/buyer/public_markets/#{identifier}/configure")
end

When('I create a defense public market with the following details:') do |table|
  @public_market_params = table.rows_hash

  header 'Authorization', nil

  token = @access_token || @previous_token

  header 'Authorization', "Bearer #{token}" if token
  header 'Content-Type', 'application/json'

  post '/api/v1/public_markets', { public_market: @public_market_params }.to_json

  @response_status = last_response.status
  @response_body = JSON.parse(last_response.body) if last_response.body.present?
  @last_api_response = @response_body
rescue JSON::ParserError
  @response_body = nil
  @last_api_response = nil
end
