# frozen_string_literal: true

Given('the following categories with labels exist:') do |table|
  table.hashes.each do |row|
    create(:category, key: row['key'], buyer_label: row['buyer_label'])
  end
end

Given('the following subcategories with labels exist:') do |table|
  table.hashes.each do |row|
    category = Category.find_by!(key: row['category_key'])
    create(:subcategory, key: row['key'], category:, buyer_label: row['buyer_label'])
  end
end

Given('I am not logged in') do
  logout(:admin_user)
end

When('I visit the new market attribute page') do
  visit new_admin_socle_de_base_path
end

When('I fill in the creation form with valid manual params') do
  select 'Text input', from: 'market_attribute[input_type]'
  select "Identité de l'entreprise", from: 'market_attribute[category_key]'
  select 'Identification', from: 'market_attribute[subcategory_key]'
  fill_in 'market_attribute[buyer_name]', with: 'Numéro SIRET'
  fill_in 'market_attribute[candidate_name]', with: 'Votre SIRET'
  check "market_type_#{MarketType.find_by!(code: 'works').id}"
end

When('I fill in the creation form with valid API params') do
  select 'Text input', from: 'market_attribute[input_type]'
  choose 'market_attribute_source_api'
  fill_in 'market_attribute[api_name]', with: 'Insee'
  fill_in 'market_attribute[api_key]', with: 'siret'
  select "Identité de l'entreprise", from: 'market_attribute[category_key]'
  select 'Identification', from: 'market_attribute[subcategory_key]'
  fill_in 'market_attribute[buyer_name]', with: 'SIRET API'
  check "market_type_#{MarketType.find_by!(code: 'works').id}"
end

When('I fill in the creation form without buyer_name') do
  select 'Text input', from: 'market_attribute[input_type]'
  select "Identité de l'entreprise", from: 'market_attribute[category_key]'
  select 'Identification', from: 'market_attribute[subcategory_key]'
  check "market_type_#{MarketType.find_by!(code: 'works').id}"
end

When('I fill in the creation form without market types') do
  select 'Text input', from: 'market_attribute[input_type]'
  select "Identité de l'entreprise", from: 'market_attribute[category_key]'
  select 'Identification', from: 'market_attribute[subcategory_key]'
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
  expect(page).to have_css('legend', text: block_title)
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

Then('I should be redirected to the login page') do
  expect(page).to have_current_path(new_admin_user_session_path)
end
