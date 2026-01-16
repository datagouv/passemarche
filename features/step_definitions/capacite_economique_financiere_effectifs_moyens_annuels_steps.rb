World(FactoryBot::Syntax::Methods)

# Background steps
Given('a public market with capacite_economique_financiere_effectifs_moyens_annuels field exists') do
  @editor = create(:editor, :authorized_and_active)
  @public_market = create(:public_market, :completed, editor: @editor)

  @effectifs_attr = MarketAttribute.find_or_create_by(key: 'capacite_economique_financiere_effectifs_moyens_annuels') do |attr|
    attr.input_type = 'capacite_economique_financiere_effectifs_moyens_annuels'
    attr.category_key = 'capacites_techniques_professionnelles'
    attr.subcategory_key = 'capacites_techniques_professionnelles_effectifs'
    attr.mandatory = true
  end
  @effectifs_attr.public_markets << @public_market unless @effectifs_attr.public_markets.include?(@public_market)
end

Given('a candidate starts an application for this market \(effectifs moyens annuels)') do
  @market_application = create(:market_application,
    public_market: @public_market,
    siret: '73282932000074')
end

# Navigation steps
When('I visit the economic capacities step \(effectifs moyens annuels)') do
  visit "/candidate/market_applications/#{@market_application.identifier}/capacites_techniques_professionnelles_effectifs"
end

When('I fill in average staff data:') do |table|
  table.hashes.each do |row|
    year_key = row['year']
    find("input[name*='#{year_key}_year']").set(row['year_value'])
    find("input[name*='#{year_key}_average_staff']").set(row['average_staff'])
    find("input[name*='#{year_key}_management_staff']").set(row['management_staff']) if row['management_staff'].present?
  end
end

When('I navigate back to the economic capacities step \(effectifs moyens annuels\)') do
  visit "/candidate/market_applications/#{@market_application.identifier}/capacites_techniques_professionnelles_effectifs"
end

When('I visit the effectifs summary step') do
  visit "/candidate/market_applications/#{@market_application.identifier}/summary"
end

Then('I should see effectifs form with labels:') do |table|
  table.raw.each do |row|
    expect(page).to have_content(row.first)
  end
end

Then('I should see effectifs form with table headers:') do |table|
  table.raw.first.each do |header|
    expect(page).to have_css('th', text: header)
  end
end

# Verification steps - Display
Then('I should see the effectifs title {string}') do |title|
  expect(page).to have_content(title, normalize_ws: true)
end

Then('I should see the effectifs description {string}') do |description|
  expect(page).to have_content(description)
end

Then('I should see a table with effectifs headers:') do |table|
  table.raw.first.each do |header|
    expect(page).to have_content(header)
  end
end

# Form interaction steps
When('I fill in partial average staff data:') do |table|
  table.hashes.each do |row|
    year_key = row['year']
    find("input[name*='#{year_key}_year']").set(row['year_value']) if row['year_value'].present?
    find("input[name*='#{year_key}_average_staff']").set(row['average_staff']) if row['average_staff'].present?
    find("input[name*='#{year_key}_management_staff']").set(row['management_staff']) if row['management_staff'].present?
  end
end

When('I fill in invalid average staff data:') do |table|
  table.hashes.each do |row|
    year_key = row['year']
    find("input[name*='#{year_key}_year']").set(row['year_value'])
    find("input[name*='#{year_key}_average_staff']").set(row['average_staff'])
    find("input[name*='#{year_key}_management_staff']").set(row['management_staff']) if row['management_staff'].present?
  end
end

Then('I should see the average staff data displayed:') do |table|
  table.hashes.each do |row|
    expect(page.text).to match(/#{Regexp.escape(row['year'])}/i)
    expect(page).to have_content(row['year_value'])
    expect(page).to have_content(row['average_staff'])
    expect(page).to have_content(row['management_staff']) if row['management_staff'].present?
  end
end

When('I fill in valid average staff data and submit') do
  find("input[name*='year_1_year']").set('2024')
  find("input[name*='year_1_average_staff']").set('30')
  find("input[name*='year_1_management_staff']").set('5')
  find("input[name*='year_2_year']").set('2023')
  find("input[name*='year_2_average_staff']").set('32')
  find("input[name*='year_2_management_staff']").set('7')
  find("input[name*='year_3_year']").set('2022')
  find("input[name*='year_3_average_staff']").set('35')
  find("input[name*='year_3_management_staff']").set('8')

  click_button 'Suivant'
end

# Data verification steps
Then('the year data should be saved with correct structure') do
  @market_application.reload
  response = @market_application.market_attribute_responses.last

  expect(response).to be_present
  expect(response.type).to eq('CapaciteEconomiqueFinanciereEffectifsMoyensAnnuels')
  expect(response.value).to be_a(Hash)
  expect(response.value).to have_key('year_1')
  expect(response.value['year_1']).to have_key('year')
  expect(response.value['year_1']).to have_key('average_staff')
  expect(response.value['year_1']).to have_key('management_staff')
end

Then('the effectifs response should be created with class {string}') do |class_name|
  @market_application.reload
  response = @market_application.market_attribute_responses.last
  expect(response.class.name).to eq(class_name)
end

Then('the effectifs response should have the correct JSON structure') do
  @market_application.reload
  response = @market_application.market_attribute_responses.last

  expected_structure = %w[year_1 year_2 year_3]
  expected_structure.each do |year|
    expect(response.value).to have_key(year)
    expect(response.value[year]).to have_key('year')
    expect(response.value[year]).to have_key('average_staff')
    expect(response.value[year]).to have_key('management_staff')
  end
end

# Field persistence verification steps
Then('the average_staff field for year_{int} should contain {string}') do |year_num, value|
  year_key = "year_#{year_num}"
  field_element = page.find("input[name*='#{year_key}_average_staff']")
  expect(field_element.value).to eq(value)
end

Then('the year field for year_{int} should contain {string}') do |year_num, value|
  year_key = "year_#{year_num}"
  field_element = page.find("input[name*='#{year_key}_year']")
  expect(field_element.value).to eq(value)
end

Then('the management_staff field for year_{int} should contain {string}') do |year_num, value|
  year_key = "year_#{year_num}"
  field_element = page.find("input[name*='#{year_key}_management_staff']")
  expect(field_element.value).to eq(value)
end

# Validation and submission steps
Then('the effectifs form should be submitted successfully') do
  expect(page).not_to have_css('.fr-message--error')
  expect(page).not_to have_content('doit être rempli')
end

Then('the effectifs form should not be submitted') do
  expect(page).to have_current_path(/capacites_techniques_professionnelles_effectifs/)
  expect(page).to have_css('.fr-message--error')
end

Then('I should see the effectifs validation errors:') do |table|
  table.hashes.each do |row|
    error_message = row['error']
    expect(page).to have_content(error_message)
  end
end

# Summary display verification steps
Given('I have submitted valid average staff data:') do |table|
  @market_application.reload

  response = MarketAttributeResponse::CapaciteEconomiqueFinanciereEffectifsMoyensAnnuels.new(
    market_application: @market_application,
    market_attribute: @effectifs_attr
  )

  value_hash = {}
  table.hashes.each do |row|
    year_key = row['year']
    value_hash[year_key] = {
      'year' => row['year_value'].to_i,
      'average_staff' => row['average_staff'].to_i,
      'management_staff' => row['management_staff'].to_i
    }
  end

  response.value = value_hash
  response.save!
end

Then('I should see the average staff data displayed in a table:') do |table|
  table.hashes.each do |row|
    expect(page).to have_content(row['year'])
    expect(page).to have_content(row['year_value'])
    expect(page).to have_content(row['average_staff'])
  end
end
