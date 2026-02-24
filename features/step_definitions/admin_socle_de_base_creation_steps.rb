# frozen_string_literal: true

Given('the following subcategories with labels exist:') do |table|
  table.hashes.each do |row|
    category = Category.find_by!(key: row['category_key'])
    create(:subcategory,
      key: row['key'],
      category:,
      buyer_label: row['buyer_label'],
      candidate_label: row['candidate_label'])
  end
end

Given('an existing API market attribute with api_name {string} and api_key {string}') do |api_name, api_key|
  create(:market_attribute, api_name:, api_key:)
end

When('I visit the new market attribute page') do
  visit new_admin_socle_de_base_path
end

When('I fill in the creation form with valid manual params') do
  subcategory = Subcategory.find_by!(key: 'identification')

  select 'Text input', from: 'market_attribute[input_type]'
  find('#market_attribute_subcategory_id', visible: false).set(subcategory.id)
  fill_in 'market_attribute[buyer_name]', with: 'Numéro SIRET'
  fill_in 'market_attribute[candidate_name]', with: 'Votre SIRET'
  check "market_type_#{MarketType.find_by!(code: 'works').id}"
end

When('I fill in the creation form with valid API params') do
  subcategory = Subcategory.find_by!(key: 'identification')

  select 'Text input', from: 'market_attribute[input_type]'
  choose 'config_api'
  api_name_select = find('#market_attribute_api_name', visible: false)
  api_name_select.find("option[value='Insee']", visible: false).select_option
  api_key_select = find('#market_attribute_api_key', visible: false)
  api_key_select.native.add_child('<option value="siret" selected>siret</option>')
  find('#market_attribute_subcategory_id', visible: false).set(subcategory.id)
  fill_in 'market_attribute[buyer_name]', with: 'SIRET API'
  fill_in 'market_attribute[candidate_name]', with: 'Votre SIRET API'
  check "market_type_#{MarketType.find_by!(code: 'works').id}"
end

When('I fill in the creation form without buyer_name') do
  subcategory = Subcategory.find_by!(key: 'identification')

  select 'Text input', from: 'market_attribute[input_type]'
  find('#market_attribute_subcategory_id', visible: false).set(subcategory.id)
  check "market_type_#{MarketType.find_by!(code: 'works').id}"
end

When('I fill in the creation form without market types') do
  subcategory = Subcategory.find_by!(key: 'identification')

  select 'Text input', from: 'market_attribute[input_type]'
  find('#market_attribute_subcategory_id', visible: false).set(subcategory.id)
  fill_in 'market_attribute[buyer_name]', with: 'Test Field'
end

When('I submit the creation form') do
  click_on 'Créer le champ'
end

Then('I should be redirected to the socle de base index') do
  expect(page).to have_current_path(admin_socle_de_base_index_path)
end

Then('I should see a success message {string}') do |message|
  expect(page).to have_content(message)
end

Then('I should see the form block {string}') do |block_title|
  expect(page).to have_css('h2', text: block_title)
end

Then('I should see an error in the form') do
  expect(page).to have_css('.fr-alert--error')
end

Given('I note the current market attribute count') do
  @initial_market_attribute_count = MarketAttribute.count
end

Then('the market attribute count should not have changed') do
  expect(MarketAttribute.count).to eq(@initial_market_attribute_count)
end
