# frozen_string_literal: true

When('I visit the setup page for my public market') do
  @market_identifier = @last_api_response['identifier']
  visit step_buyer_public_market_path(identifier: @market_identifier, id: :setup)
end

When('I visit the first category page for my public market') do
  @market_identifier = @last_api_response['identifier']
  public_market = PublicMarket.find_by!(identifier: @market_identifier)
  presenter = PublicMarketPresenter.new(public_market)
  @first_category = presenter.wizard_steps[1] # First category after :setup
  visit step_buyer_public_market_path(identifier: @market_identifier, id: @first_category)
end

When('I visit a category page with optional fields for my public market') do
  @market_identifier = @last_api_response['identifier']
  public_market = PublicMarket.find_by!(identifier: @market_identifier)
  presenter = PublicMarketPresenter.new(public_market)

  # Find a category that has optional fields
  category_with_optionals = presenter.wizard_steps.find do |step|
    next if %i[setup summary].include?(step)

    presenter.optional_fields_for_category?(step.to_s)
  end

  visit step_buyer_public_market_path(identifier: @market_identifier, id: category_with_optionals)
end

When('I visit the summary page for my public market') do
  @market_identifier = @last_api_response['identifier']
  visit step_buyer_public_market_path(identifier: @market_identifier, id: :summary)
end

When('I navigate through all category steps to summary') do
  public_market = PublicMarket.find_by!(identifier: @market_identifier)
  presenter = PublicMarketPresenter.new(public_market)

  # Skip setup (already done) and summary (our target)
  category_steps = presenter.wizard_steps.reject { |s| %i[setup summary].include?(s) }

  category_steps.each do
    # For steps with optional fields, answer "Non" to skip adding optionals
    choose 'Non', allow_label_click: true if page.has_css?('input[name="additional_fields_choice"]')

    # Click the submit button
    find('input[type="submit"]').click
  end
end

Given('I am on the summary page for my public market') do
  @market_identifier = @last_api_response['identifier']
  visit step_buyer_public_market_path(identifier: @market_identifier, id: :summary)
end

Then('I should be on the setup page') do
  expect(page).to have_current_path(step_buyer_public_market_path(@market_identifier, :setup))
end

Then('I should be on the first category page') do
  public_market = PublicMarket.find_by!(identifier: @market_identifier)
  presenter = PublicMarketPresenter.new(public_market)
  first_category = presenter.wizard_steps[1]
  expect(page).to have_current_path(step_buyer_public_market_path(@market_identifier, first_category))
end

Then('I should be on a category page') do
  public_market = PublicMarket.find_by!(identifier: @market_identifier)
  presenter = PublicMarketPresenter.new(public_market)
  category_steps = presenter.wizard_steps.reject { |s| %i[setup summary].include?(s) }

  current_path = page.current_path
  matched = category_steps.any? do |step|
    current_path == step_buyer_public_market_path(@market_identifier, step)
  end

  expect(matched).to be true
end

Then('I should be on the summary page') do
  expect(page).to have_current_path(step_buyer_public_market_path(@market_identifier, :summary))
end

Then('I should see a {string} button') do |button_text|
  expect(page).to have_link(button_text)
end

Then('I should see a button {string}') do |button_text|
  expect(page).to have_button(button_text, exact: false, disabled: :all)
end

Then('I should see a disabled button {string}') do |button_text|
  expect(page).to have_button(button_text, disabled: true, exact: false)
end

When('I click on {string}') do |link_or_button_text|
  if link_or_button_text == "Débuter l'activation de"
    submit_button = page.find('input[type=submit]', match: :first)
    submit_button.click
  elsif link_or_button_text == 'Suivant'
    # For steps with optional fields, answer "Non" to skip adding optionals
    choose 'Non', allow_label_click: true if page.has_css?('input[name="additional_fields_choice"]')

    find('input[type="submit"]').click if page.has_css?('input[type="submit"]')
  elsif link_or_button_text == 'Précédent'
    click_link 'Précédent'
  elsif page.has_button?(link_or_button_text)
    click_button link_or_button_text
  else
    click_link link_or_button_text
  end
end

Then('I should see a stepper') do
  expect(page).to have_css('.fr-stepper')
end

Then('the stepper should indicate the first category step as current') do
  expect(page).to have_css('.fr-stepper')
  expect(page).to have_css('.fr-stepper__steps[data-fr-current-step="1"]')
end

When('I check the {string} checkbox') do |checkbox_name|
  if checkbox_name == 'defense_industry'
    check('public_market_add_defense_market_type')
  else
    check(checkbox_name)
  end
end

Then('the public market should be marked as defense_industry') do
  @market_identifier = @last_api_response['identifier']
  public_market = PublicMarket.find_by(identifier: @market_identifier)
  expect(public_market.market_type_codes).to include('defense')
end

Then('the public market should not be marked as defense_industry') do
  @market_identifier = @last_api_response['identifier']
  public_market = PublicMarket.find_by(identifier: @market_identifier)
  expect(public_market.market_type_codes).not_to include('defense')
end

Then('the defense_industry checkbox should be disabled and checked') do
  expect(page).to have_field('defense_industry', checked: true, disabled: true)
end

Then('the public market should have all required attributes from its market types') do
  public_market = PublicMarket.find_by!(identifier: @market_identifier)

  market_types = MarketType.where(code: public_market.market_type_codes)
  expected_required_attributes = market_types
    .flat_map(&:required_attributes)
    .uniq

  actual_attributes = public_market.market_attributes.to_a

  expect(actual_attributes).to match_array(expected_required_attributes)
end
