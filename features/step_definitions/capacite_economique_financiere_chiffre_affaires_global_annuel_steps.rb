# frozen_string_literal: true

require 'webmock/cucumber'

World(FactoryBot::Syntax::Methods)

CHIFFRE_AFFAIRES_ATTRS = {
  key: 'capacite_economique_financiere_chiffre_affaires_global_annuel',
  input_type: 'capacite_economique_financiere_chiffre_affaires_global_annuel',
  category_key: 'capacite_economique_financiere',
  subcategory_key: 'capacite_economique_financiere_chiffre_affaires',
  mandatory: true,
  api_name: 'dgfip_chiffres_affaires',
  api_key: 'chiffres_affaires_data'
}.freeze

Given('a public market with capacite_economique_financiere_chiffre_affaires_global_annuel field exists') do
  @chiffre_affaires_attr = setup_market_with_attribute(**CHIFFRE_AFFAIRES_ATTRS)
end

Given('a market attribute exists for chiffre affaires global annuel') do
  @chiffre_affaires_attr = setup_market_with_attribute(**CHIFFRE_AFFAIRES_ATTRS)
end

Given('a candidate starts an application for this market') do
  start_candidate_application(siret: '41816609600069')
end

When('I visit the economic capacities step') do
  visit "/candidate/market_applications/#{@market_application.identifier}/capacite_economique_financiere_chiffre_affaires"
end

When('I visit the summary step') do
  visit "/candidate/market_applications/#{@market_application.identifier}/summary"
end

When('I navigate back to the economic capacities step') do
  visit "/candidate/market_applications/#{@market_application.identifier}/capacite_economique_financiere_chiffre_affaires"
end

Then('I should see the title {string}') do |title|
  expect(page).to have_content(title)
end

Then('I should see the description {string}') do |description|
  expect(page).to have_content(description)
end

Then('I should see a table with headers:') do |table|
  table.raw.first.each { |header| expect(page).to have_content(header) }
end

Then('I should see {int} rows with labels:') do |count, table|
  table.raw.each { |row| expect(page).to have_content(row.first) }
  expect(page).to have_css('tbody tr', count:)
end

When('I fill in the turnover data:') do |table|
  fill_in_turnover_table(table)
end

When('I fill in turnover data:') do |table|
  fill_in_turnover_table(table)
end

When('I fill in partial turnover data:') do |table|
  table.hashes.each do |row|
    year_key = row['year']
    find("input[name*='#{year_key}_turnover']").set(row['turnover']) if row['turnover'].present?
    find("input[name*='#{year_key}_market_percentage']").set(row['percentage']) if row['percentage'].present?
    find("input[name*='#{year_key}_fiscal_year_end']").set(row['fiscal_year_end']) if row['fiscal_year_end'].present?
  end
end

When('I fill in invalid turnover data:') do |table|
  fill_in_turnover_table(table)
end

When('I fill in valid turnover data and submit') do
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

Then('the economic capacity form should be submitted successfully') do
  expect(page).not_to have_css('.fr-message--error')
  expect(page).not_to have_content('doit être rempli')
end

Then('the economic capacity form should not be submitted') do
  expect(page).to have_current_path(/capacite_economique_financiere_chiffre_affaires/)
  expect(page).to have_css('.fr-message--error')
end

Then('I should see validation errors:') do |table|
  table.hashes.each { |row| expect(page).to have_content(row['error']) }
end

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
  expect(response.value['year_1']['turnover']).to eq(500_000)
  expect(response.value['year_1']['fiscal_year_end']).to eq('2023-12-31')
  expect(response.value['year_1']['market_percentage']).to be_blank
  expect(response.value['year_2']['market_percentage']).to eq(80)
  expect(response.value['year_2']['turnover']).to be_blank
  expect(response.value['year_3']['turnover']).to eq(400_000)
  expect(response.value['year_3']['market_percentage']).to eq(70)
  expect(response.value['year_3']['fiscal_year_end']).to eq('2021-12-31')
end

Then('the economic capacity response should be created with class {string}') do |class_name|
  @market_application.reload
  expect(@market_application.market_attribute_responses.last.class.name).to eq(class_name)
end

Then('the response should have the correct JSON structure') do
  @market_application.reload
  response = @market_application.market_attribute_responses.last
  %w[year_1 year_2 year_3].each do |year|
    expect(response.value).to have_key(year)
    expect(response.value[year]).to include('turnover', 'market_percentage', 'fiscal_year_end')
  end
end

Then('the form should have a hidden type field with value {string}') do |type_value|
  expect(page).to have_field('market_application[market_attribute_responses_attributes][0][type]', with: type_value, type: 'hidden')
end

Given('I have submitted valid turnover data:') do |table|
  @market_application.reload
  response = MarketAttributeResponse::CapaciteEconomiqueFinanciereChiffreAffairesGlobalAnnuel.new(
    market_application: @market_application,
    market_attribute: @chiffre_affaires_attr
  )
  response.value = table.hashes.each_with_object({}) do |row, hash|
    hash[row['year']] = {
      'turnover' => row['turnover'].to_i,
      'market_percentage' => row['percentage'].to_i,
      'fiscal_year_end' => row['fiscal_year_end']
    }
  end
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

Then('the turnover field for year_{int} should contain {string}') do |year_num, value|
  expect(page.find("input[name*='year_#{year_num}_turnover']").value).to eq(value)
end

Then('the percentage field for year_{int} should contain {string}') do |year_num, value|
  expect(page.find("input[name*='year_#{year_num}_market_percentage']").value).to eq(value)
end

Then('the fiscal_year_end field for year_{int} should contain {string}') do |year_num, value|
  expect(page.find("input[name*='year_#{year_num}_fiscal_year_end']").value).to eq(value)
end

def fill_in_turnover_table(table)
  table.hashes.each do |row|
    year_key = row['year']
    find("input[name*='#{year_key}_turnover']").set(row['turnover'])
    find("input[name*='#{year_key}_market_percentage']").set(row['percentage'])
    find("input[name*='#{year_key}_fiscal_year_end']").set(row['fiscal_year_end'])
  end
end
