# frozen_string_literal: true

require 'webmock/cucumber'

World(FactoryBot::Syntax::Methods)

Given('a public market with capacite_economique_financiere_chiffre_affaires_global_annuel field exists') do
  # Clean up any existing test data
  MarketApplication.where("identifier LIKE 'VR-2025-TEST%'").destroy_all
  PublicMarket.where("name LIKE 'Test Market%'").destroy_all
  Editor.where("name LIKE 'Test Editor%'").destroy_all

  @editor = create(:editor, :authorized_and_active, name: "Test Editor #{Time.current.to_i}")
  @public_market = create(:public_market, :completed, editor: @editor, name: "Test Market #{Time.current.to_i}")

  @chiffre_affaires_attr = MarketAttribute.find_or_create_by(key: 'capacite_economique_financiere_chiffre_affaires_global_annuel') do |attr|
    attr.input_type = 'capacite_economique_financiere_chiffre_affaires_global_annuel'
    attr.category_key = 'capacite_economique_financiere'
    attr.subcategory_key = 'chiffre_affaires'
    attr.mandatory = true
    attr.api_name = 'dgfip_chiffres_affaires'
    attr.api_key = 'chiffres_affaires_data'
  end
  @chiffre_affaires_attr.public_markets << @public_market unless @chiffre_affaires_attr.public_markets.include?(@public_market)
end

Given('a market attribute exists for chiffre affaires global annuel') do
  # Clean up any existing test data
  MarketApplication.where("identifier LIKE 'VR-2025-TEST%'").destroy_all
  PublicMarket.where("name LIKE 'Test Market%'").destroy_all
  Editor.where("name LIKE 'Test Editor%'").destroy_all

  @editor = create(:editor, :authorized_and_active, name: "Test Editor #{Time.current.to_i}")
  @public_market = create(:public_market, :completed, editor: @editor, name: "Test Market #{Time.current.to_i}")

  @chiffre_affaires_attr = MarketAttribute.find_or_create_by(key: 'capacite_economique_financiere_chiffre_affaires_global_annuel') do |attr|
    attr.input_type = 'capacite_economique_financiere_chiffre_affaires_global_annuel'
    attr.category_key = 'capacite_economique_financiere'
    attr.subcategory_key = 'chiffre_affaires'
    attr.mandatory = true
    attr.api_name = 'dgfip_chiffres_affaires'
    attr.api_key = 'chiffres_affaires_data'
  end
  @chiffre_affaires_attr.public_markets << @public_market unless @chiffre_affaires_attr.public_markets.include?(@public_market)
end

Given('a candidate starts an application for this market') do
  @market_application = create(:market_application,
    public_market: @public_market,
    siret: '41816609600069')
end

# Navigation steps
When('I visit the economic capacities step') do
  visit "/candidate/market_applications/#{@market_application.identifier}/chiffre_affaires"

  market_attr = @market_application.public_market.market_attributes.find_by(
    key: 'capacite_economique_financiere_chiffre_affaires_global_annuel'
  )

  if market_attr&.api_name == 'dgfip_chiffres_affaires'
    sleep 0.1

    visit current_path
  end
end

When('I visit the summary step') do
  visit "/candidate/market_applications/#{@market_application.identifier}/summary"
end

When('I navigate back to the economic capacities step') do
  visit "/candidate/market_applications/#{@market_application.identifier}/chiffre_affaires"
end

# Verification steps - Display
Then('I should see the title {string}') do |title|
  expect(page).to have_content(title)
end

Then('I should see the description {string}') do |description|
  expect(page).to have_content(description)
end

Then('I should see a table with headers:') do |table|
  table.raw.first.each do |header|
    expect(page).to have_content(header)
  end
end

Then('I should see {int} rows with labels:') do |count, table|
  table.raw.each do |row|
    expect(page).to have_content(row.first)
  end
  # Verify we have the expected number of rows
  expect(page).to have_css('tbody tr', count:)
end

# Form interaction steps
When('I fill in the turnover data:') do |table|
  table.hashes.each do |row|
    year_key = row['year']
    # Use partial selectors that match the Rails-generated field names
    find("input[name*='#{year_key}_turnover']").set(row['turnover'])
    find("input[name*='#{year_key}_market_percentage']").set(row['percentage'])
    find("input[name*='#{year_key}_fiscal_year_end']").set(row['fiscal_year_end'])
  end
end

When('I fill in partial turnover data:') do |table|
  table.hashes.each do |row|
    year_key = row['year']
    # Use partial selectors to match the dynamic field names
    if row['turnover'].present?
      turnover_field = find("input[name*='#{year_key}_turnover']")
      turnover_field.set(row['turnover'])
    end

    if row['percentage'].present?
      percentage_field = find("input[name*='#{year_key}_market_percentage']")
      percentage_field.set(row['percentage'])
    end

    if row['fiscal_year_end'].present?
      fiscal_field = find("input[name*='#{year_key}_fiscal_year_end']")
      fiscal_field.set(row['fiscal_year_end'])
    end
  end
end

When('I fill in invalid turnover data:') do |table|
  table.hashes.each do |row|
    year_key = row['year']
    # Use partial selectors to match the dynamic field names
    turnover_field = find("input[name*='#{year_key}_turnover']")
    percentage_field = find("input[name*='#{year_key}_market_percentage']")
    fiscal_field = find("input[name*='#{year_key}_fiscal_year_end']")

    turnover_field.set(row['turnover'])
    percentage_field.set(row['percentage'])
    fiscal_field.set(row['fiscal_year_end'])
  end
end

When('I fill in turnover data:') do |table|
  table.hashes.each do |row|
    year_key = row['year']
    # Use partial selectors to match the dynamic field names
    turnover_field = find("input[name*='#{year_key}_turnover']")
    percentage_field = find("input[name*='#{year_key}_market_percentage']")
    fiscal_field = find("input[name*='#{year_key}_fiscal_year_end']")

    turnover_field.set(row['turnover'])
    percentage_field.set(row['percentage'])
    fiscal_field.set(row['fiscal_year_end'])
  end
end

When('I fill in valid turnover data and submit') do
  # Use partial selectors to match the dynamic field names
  find("input[name*='year_1_turnover']").set('500000')
  find("input[name*='year_1_market_percentage']").set('75')
  find("input[name*='year_1_fiscal_year_end']").set('2023-12-31')
  find("input[name*='year_2_turnover']").set('450000')
  find("input[name*='year_2_market_percentage']").set('80')
  find("input[name*='year_2_fiscal_year_end']").set('2022-12-31')
  find("input[name*='year_3_turnover']").set('400000')
  find("input[name*='year_3_market_percentage']").set('70')
  find("input[name*='year_3_fiscal_year_end']").set('2021-12-31')

  click_button 'Suivant'
end

# Button click step is already defined in candidate_flow_comprehensive_steps.rb

# Validation and submission steps
Then('the economic capacity form should be submitted successfully') do
  expect(page).not_to have_css('.fr-message--error')
  expect(page).not_to have_content('doit être rempli')
end

Then('the economic capacity form should not be submitted') do
  # Check that we're still on the economic capacities page (not redirected to next step)
  expect(page).to have_current_path(/chiffre_affaires/)
  # Also check for presence of error messages
  expect(page).to have_css('.fr-message--error')
end

Then('I should see validation errors:') do |table|
  table.hashes.each do |row|
    error_message = row['error']
    expect(page).to have_content(error_message)
  end
end

# Data verification steps
Then('the data should be saved with correct structure') do
  @market_application.reload
  response = @market_application.market_attribute_responses.last

  expect(response).to be_present
  expect(response.type).to eq('CapaciteEconomiqueFinanciereChiffreAffairesGlobalAnnuel')
  expect(response.value).to be_a(Hash)
  expect(response.value).to have_key('year_1')
  expect(response.value['year_1']).to have_key('turnover')
  expect(response.value['year_1']).to have_key('market_percentage')
  expect(response.value['year_1']).to have_key('fiscal_year_end')
end

Then('the data should be saved with partial completion') do
  @market_application.reload
  response = @market_application.market_attribute_responses.last

  expect(response).to be_present
  expect(response.type).to eq('CapaciteEconomiqueFinanciereChiffreAffairesGlobalAnnuel')
  expect(response.value).to be_a(Hash)

  # Verify that partial data is saved correctly
  # year_1 should have turnover and fiscal_year_end but no market_percentage
  expect(response.value).to have_key('year_1')
  expect(response.value['year_1']['turnover']).to eq(500_000)
  expect(response.value['year_1']['fiscal_year_end']).to eq('2023-12-31')
  expect(response.value['year_1']['market_percentage']).to be_blank

  # year_2 should have market_percentage only
  expect(response.value).to have_key('year_2')
  expect(response.value['year_2']['market_percentage']).to eq(80)
  expect(response.value['year_2']['turnover']).to be_blank
  expect(response.value['year_2']['fiscal_year_end']).to be_blank

  # year_3 should have all fields filled
  expect(response.value).to have_key('year_3')
  expect(response.value['year_3']['turnover']).to eq(400_000)
  expect(response.value['year_3']['market_percentage']).to eq(70)
  expect(response.value['year_3']['fiscal_year_end']).to eq('2021-12-31')
end

Then('the economic capacity response should be created with class {string}') do |class_name|
  @market_application.reload
  response = @market_application.market_attribute_responses.last
  expect(response.class.name).to eq(class_name)
end

Then('the response should have the correct JSON structure') do
  @market_application.reload
  response = @market_application.market_attribute_responses.last

  expected_structure = %w[year_1 year_2 year_3]
  expected_structure.each do |year|
    expect(response.value).to have_key(year)
    expect(response.value[year]).to have_key('turnover')
    expect(response.value[year]).to have_key('market_percentage')
    expect(response.value[year]).to have_key('fiscal_year_end')
  end
end

# STI verification steps
Then('the form should have a hidden type field with value {string}') do |type_value|
  expect(page).to have_field('market_application[market_attribute_responses_attributes][0][type]', with: type_value, type: 'hidden')
end

# Summary display verification steps
Given('I have submitted valid turnover data:') do |table|
  @market_application.reload

  # Create the response with the specified data
  response = MarketAttributeResponse::CapaciteEconomiqueFinanciereChiffreAffairesGlobalAnnuel.new(
    market_application: @market_application,
    market_attribute: @chiffre_affaires_attr
  )

  value_hash = {}
  table.hashes.each do |row|
    year_key = row['year']
    value_hash[year_key] = {
      'turnover' => row['turnover'].to_i,
      'market_percentage' => row['percentage'].to_i,
      'fiscal_year_end' => row['fiscal_year_end']
    }
  end

  response.value = value_hash
  response.save!
end

Then('I should see the turnover data displayed in a table:') do |table|
  table.hashes.each do |row|
    expect(page).to have_content(row['year'])
    expect(page).to have_content(row['turnover'])
    expect(page).to have_content(row['percentage'])
    expect(page).to have_content(row['fiscal_year_end'])
  end
end

# Field persistence verification steps
Then('the turnover field for year_{int} should contain {string}') do |year_num, value|
  year_key = "year_#{year_num}"
  # Look for any field with the year_key and turnover in the name
  field_element = page.find("input[name*='#{year_key}_turnover']")
  expect(field_element.value).to eq(value)
end

Then('the percentage field for year_{int} should contain {string}') do |year_num, value|
  year_key = "year_#{year_num}"
  field_element = page.find("input[name*='#{year_key}_market_percentage']")
  expect(field_element.value).to eq(value)
end

Then('the fiscal_year_end field for year_{int} should contain {string}') do |year_num, value|
  year_key = "year_#{year_num}"
  field_element = page.find("input[name*='#{year_key}_fiscal_year_end']")
  expect(field_element.value).to eq(value)
end
