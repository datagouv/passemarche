# frozen_string_literal: true

Given('a candidate application exists for SIRET {string}') do |siret|
  @market_application = create(:market_application, public_market: @public_market, siret:)
end

Given('the candidate application is already assigned to {string}') do |email|
  user = create(:user, email:)
  @market_application.update!(user:)
end

Given('a candidate {string} has a valid magic link token') do |email|
  @user = User.find_by(email:) || create(:user, email:)
  @user.update!(authentication_token_sent_at: Time.current)
  @magic_link_token = @user.generate_token_for(:magic_link)
end

When('I visit the first step of my application') do
  visit step_candidate_market_application_path(@market_application.identifier, :company_identification)
end

When('I fill in {string} with {string}') do |field, value|
  fill_in field, with: value
end

When('I visit the magic link') do
  visit verify_candidate_sessions_path(
    token: @magic_link_token,
    market_application_id: @market_application.identifier
  )
end

Then('I should see the authentication form') do
  expect(page).to have_selector('form[action*="candidate/sessions"]')
end

Then('an email should have been sent to {string}') do |email|
  expect(ActionMailer::Base.deliveries.last&.to).to include(email)
end

Then('I should be on the first step of my application') do
  expect(page).to have_current_path(
    step_candidate_market_application_path(@market_application.identifier, :company_identification),
    ignore_query: true
  )
end

Then('I should be authenticated') do
  expect(page).not_to have_selector('form[action*="candidate/sessions"]')
end

Then('I should see an error message') do
  expect(page).to have_selector('.fr-alert--error')
end
