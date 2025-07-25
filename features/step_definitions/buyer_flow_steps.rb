# frozen_string_literal: true

# Navigation steps
When('I visit the configure page for my public market') do
  @market_identifier = @last_api_response['identifier']
  visit step_buyer_public_market_path(@market_identifier, :configure)
end

When('I visit the required documents page for my public market') do
  @market_identifier = @last_api_response['identifier']
  visit step_buyer_public_market_path(@market_identifier, :required_fields)
end

When('I visit the optional documents page for my public market') do
  @market_identifier = @last_api_response['identifier']
  visit step_buyer_public_market_path(@market_identifier, :additional_fields)
end

When('I visit the summary page for my public market') do
  @market_identifier = @last_api_response['identifier']
  visit step_buyer_public_market_path(@market_identifier, :summary)
end

When('I navigate to required documents page') do
  # Find submit button by partial value match
  submit_button = page.find('input[type=submit]', match: :first)
  submit_button.click
end

When('I navigate to optional documents page') do
  if page.has_content?('Continuer vers les champs supplémentaires')
    click_link 'Continuer vers les champs supplémentaires'
  else
    @market_identifier = @last_api_response['identifier']
    visit step_buyer_public_market_path(@market_identifier, :additional_fields)
  end
end

When('I navigate to summary page') do
  if page.has_content?('Autoriser la candidature via')
    click_link 'Autoriser la candidature via'
  else
    @market_identifier = @last_api_response['identifier']
    visit step_buyer_public_market_path(@market_identifier, :summary)
  end
end

When('I go back to optional documents page') do
  @market_identifier = @last_api_response['identifier']
  visit step_buyer_public_market_path(@market_identifier, :additional_fields)
end

Given('I am on the summary page for my public market') do
  @market_identifier = @last_api_response['identifier']
  visit step_buyer_public_market_path(@market_identifier, :summary)
end

# Page verification steps
Then('I should be on the configure page') do
  expect(page).to have_current_path(step_buyer_public_market_path(@market_identifier, :configure))
end

Then('I should be on the required documents page') do
  expect(page).to have_current_path(step_buyer_public_market_path(@market_identifier, :required_fields))
end

Then('I should be on the optional documents page') do
  expect(page).to have_current_path(step_buyer_public_market_path(@market_identifier, :additional_fields))
end

Then('I should be on the summary page') do
  expect(page).to have_current_path(step_buyer_public_market_path(@market_identifier, :summary))
end

# Button and link interaction steps
Then('I should see a {string} button') do |button_text|
  expect(page).to have_link(button_text)
end

Then('I should see a button {string}') do |button_text|
  expect(page).to have_button(button_text, exact: false)
end

Then('I should see a disabled button {string}') do |button_text|
  expect(page).to have_button(button_text, disabled: true, exact: false)
end

When('I click on {string}') do |link_or_button_text|
  # Handle partial text matching for buttons with dynamic content
  if link_or_button_text == "Débuter l'activation de"
    # Find submit button by partial value match
    submit_button = page.find('input[type=submit]', match: :first)
    submit_button.click
  elsif page.has_button?(link_or_button_text)
    click_button link_or_button_text
  else
    click_link link_or_button_text
  end
end

# Stepper verification steps
Then('the stepper should indicate step {int} as current') do |step_number|
  expect(page).to have_css('.fr-stepper')

  case step_number
  when 1
    expect(page).to have_content('Vérification des informations obligatoires')
    expect(page).to have_content('Étape 1 sur 3')
    expect(page).to have_css('.fr-stepper__steps[data-fr-current-step="1"]')
  when 2
    expect(page).to have_content('Sélection des informations complémentaires')
    expect(page).to have_content('Étape 2 sur 2')
    expect(page).to have_css('.fr-stepper__steps[data-fr-current-step="2"]')
  end
end

# Defense checkbox steps
When('I check the {string} checkbox') do |checkbox_name|
  if checkbox_name == 'defense'
    check('public_market_defense')
  else
    check(checkbox_name)
  end
end

Then('the public market should be marked as defense') do
  @market_identifier = @last_api_response['identifier']
  public_market = PublicMarket.find_by(identifier: @market_identifier)
  expect(public_market.defense).to be(true)
end

Then('the public market should not be marked as defense') do
  @market_identifier = @last_api_response['identifier']
  public_market = PublicMarket.find_by(identifier: @market_identifier)
  expect(public_market.defense).to be(false)
end

Then('the defense checkbox should be disabled and checked') do
  expect(page).to have_field('defense', checked: true, disabled: true)
end

# Content verification steps are in fast_track_steps.rb

# Market information verification across pages
Then('market information should be consistent across all pages') do
  market_name = 'Fourniture de matériel informatique'
  lot_name = 'Lot 1 - Ordinateurs portables'

  # Check configure page
  visit step_buyer_public_market_path(@market_identifier, :configure)
  expect(page).to have_content(market_name)
  expect(page).to have_content(lot_name)

  # Check required documents page
  visit step_buyer_public_market_path(@market_identifier, :required_fields)
  expect(page).to have_content(market_name)
  expect(page).to have_content(lot_name)

  # Check optional documents page
  visit step_buyer_public_market_path(@market_identifier, :additional_fields)
  expect(page).to have_content(market_name)
  expect(page).to have_content(lot_name)

  # Check summary page
  visit step_buyer_public_market_path(@market_identifier, :summary)
  expect(page).to have_content(market_name)
  expect(page).to have_content(lot_name)
end

# Document verification steps
Then('I should see required documents listed') do
  expect(page).to have_content('Certificat de naissance de licorne')
  expect(page).to have_content('Déclaration allergie aux pizzas')
  expect(page).to have_content('Niveau d\'addiction au café')
end

Then('I should see optional documents available for selection') do
  expect(page).to have_content('Permis de pilotage de fusée')
  expect(page).to have_content('Certificat de furtivité ninja')
  expect(page).to have_content('Permis de dressage de dragons')
end
