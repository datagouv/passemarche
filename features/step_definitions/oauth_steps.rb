# frozen_string_literal: true

World(FactoryBot::Syntax::Methods)

Given('an authorized and active editor exists with credentials {string} and {string}') do |client_id, client_secret|
  @editor = FactoryBot.create(:editor, :authorized_and_active,
                              client_id: client_id,
                              client_secret: client_secret)
  @editor.ensure_doorkeeper_application!
end

Given('an unauthorized editor exists with credentials {string} and {string}') do |client_id, client_secret|
  @unauthorized_editor = FactoryBot.create(:editor,
                                           client_id: client_id,
                                           client_secret: client_secret,
                                           authorized: false)
  @unauthorized_editor.ensure_doorkeeper_application!
end

Given('an inactive editor exists with credentials {string} and {string}') do |client_id, client_secret|
  @inactive_editor = FactoryBot.create(:editor, :inactive,
                                       client_id: client_id,
                                       client_secret: client_secret)
  @inactive_editor.ensure_doorkeeper_application!
end

Given('I have a valid access token') do
  # Use the editor created in Background
  step 'I request an OAuth token with valid credentials'
  @previous_token = @response_body['access_token']
end

Given('I have a token with scope {string}') do |scope|
  # Use the editor created in Background
  step "I request an OAuth token with scope \"#{scope}\""
  @first_token = @response_body['access_token']
  @first_scope = scope
end

Given('I have an expired access token') do
  # Use the editor created in Background
  step 'I request an OAuth token with valid credentials'

  # Force token expiration by updating the created_at timestamp
  token = Doorkeeper::AccessToken.find_by(token: @response_body['access_token'])
  token.update!(created_at: 25.hours.ago)
  @expired_token = token.token
end

When('I request an OAuth token with valid credentials') do
  post '/oauth/token', {
    grant_type: 'client_credentials',
    client_id: 'test_editor_id',
    client_secret: 'test_editor_secret'
  }

  @response_status = last_response.status
  @response_body = JSON.parse(last_response.body) if last_response.body.present?
end

When('I request an OAuth token with scope {string}') do |scope|
  post '/oauth/token', {
    grant_type: 'client_credentials',
    client_id: 'test_editor_id',
    client_secret: 'test_editor_secret',
    scope: scope
  }

  @response_status = last_response.status
  @response_body = JSON.parse(last_response.body) if last_response.body.present?
end

When('I request an OAuth token with credentials {string} and {string}') do |client_id, client_secret|
  post '/oauth/token', {
    grant_type: 'client_credentials',
    client_id: client_id,
    client_secret: client_secret,
    scope: 'api_access'
  }

  @response_status = last_response.status
  @response_body = JSON.parse(last_response.body) if last_response.body.present?
end

When('I request an OAuth token without grant_type') do
  post '/oauth/token', {
    client_id: 'test_editor_id',
    client_secret: 'test_editor_secret',
    scope: 'api_access'
  }

  @response_status = last_response.status
  @response_body = JSON.parse(last_response.body) if last_response.body.present?
end

When('I request an OAuth token with invalid scope {string}') do |invalid_scope|
  post '/oauth/token', {
    grant_type: 'client_credentials',
    client_id: 'test_editor_id',
    client_secret: 'test_editor_secret',
    scope: invalid_scope
  }

  @response_status = last_response.status
  @response_body = JSON.parse(last_response.body) if last_response.body.present?
end

When('I request a new OAuth token with the same credentials') do
  post '/oauth/token', {
    grant_type: 'client_credentials',
    client_id: 'test_editor_id',
    client_secret: 'test_editor_secret',
    scope: 'api_access'
  }

  @response_status = last_response.status
  @response_body = JSON.parse(last_response.body) if last_response.body.present?
  @new_token = @response_body['access_token']
end

When('I request a new token with scope {string}') do |scope|
  post '/oauth/token', {
    grant_type: 'client_credentials',
    client_id: 'test_editor_id',
    client_secret: 'test_editor_secret',
    scope: scope
  }

  @response_status = last_response.status
  @response_body = JSON.parse(last_response.body) if last_response.body.present?
  @second_token = @response_body['access_token']
  @second_scope = scope
end

When('I request a new OAuth token with valid credentials') do
  post '/oauth/token', {
    grant_type: 'client_credentials',
    client_id: 'test_editor_id',
    client_secret: 'test_editor_secret',
    scope: 'api_access'
  }

  @response_status = last_response.status
  @response_body = JSON.parse(last_response.body) if last_response.body.present?
end

Then('I should receive a valid access token') do
  expect(@response_status).to eq(200)
  expect(@response_body).to have_key('access_token')
  expect(@response_body['access_token']).to be_present
  expect(@response_body['token_type']).to eq('Bearer')
end

Then('the token should expire in {int} hours') do |hours|
  expect(@response_body['expires_in']).to eq(hours * 3600)
end

Then('the token should have {string} scope') do |expected_scope|
  expect(@response_body['scope']).to eq(expected_scope)
end

Then('I should receive an {string} error') do |error_type|
  expect(@response_body).to have_key('error')
  expect(@response_body['error']).to eq(error_type)
end

Then('the response status should be {int}') do |expected_status|
  expect(@response_status).to eq(expected_status)
end

Then('I should receive a new valid access token') do
  expect(@response_status).to eq(200)
  expect(@response_body).to have_key('access_token')
  expect(@response_body['access_token']).to be_present
  expect(@response_body['token_type']).to eq('Bearer')
end

Then('the previous token should be revoked') do
  previous_token_record = Doorkeeper::AccessToken.find_by(token: @previous_token)
  expect(previous_token_record).to be_revoked
end

Then('the new token should be different from the previous one') do
  expect(@new_token).not_to eq(@previous_token)
end

Then('I should have two different tokens') do
  expect(@first_token).to be_present
  expect(@second_token).to be_present
  expect(@first_token).not_to eq(@second_token)
end

Then('both tokens should be valid') do
  first_token_record = Doorkeeper::AccessToken.find_by(token: @first_token)
  second_token_record = Doorkeeper::AccessToken.find_by(token: @second_token)

  expect(first_token_record).not_to be_revoked
  expect(second_token_record).not_to be_revoked
  expect(first_token_record).not_to be_expired
  expect(second_token_record).not_to be_expired
end

Then('each token should have its respective scope') do
  first_token_record = Doorkeeper::AccessToken.find_by(token: @first_token)
  second_token_record = Doorkeeper::AccessToken.find_by(token: @second_token)

  expect(first_token_record.scopes.to_s).to eq(@first_scope)
  expect(second_token_record.scopes.to_s).to eq(@second_scope)
end

Then('the new token should be different from the expired one') do
  expect(@response_body['access_token']).not_to eq(@expired_token)
end
