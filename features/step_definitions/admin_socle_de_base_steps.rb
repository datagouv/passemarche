# frozen_string_literal: true

Given('the following market attributes exist:') do |table|
  MarketAttribute.delete_all
  table.hashes.each do |row|
    create(:market_attribute,
      key: row['key'],
      category_key: row['category_key'],
      subcategory_key: row['subcategory_key'],
      mandatory: row['mandatory'] == 'true',
      api_name: row['api_name'].presence,
      api_key: row['api_name'].present? ? 'test_key' : nil)
  end
end

When('I visit the socle de base page') do
  visit admin_socle_de_base_index_path
end

Then('I should see the page title {string}') do |title|
  expect(page).to have_css('h1', text: title)
end

Then('the tab {string} should be active') do |tab_name|
  expect(page).to have_css('.fr-tabs__tab--selected', text: tab_name)
end

Then('the tab {string} should not be active') do |tab_name|
  expect(page).to have_css('.fr-tabs__tab', text: tab_name)
  expect(page).not_to have_css('.fr-tabs__tab--selected', text: tab_name)
end

Then('I should see the attribute {string}') do |key|
  expect(page).to have_css("[data-testid='market-attribute-#{key}']")
end

Then('I should not see the attribute {string}') do |key|
  expect(page).not_to have_css("[data-testid='market-attribute-#{key}']")
end

Then('I should see the button {string}') do |button_text|
  expect(page).to have_link(button_text)
end

Then('I should see the manage dropdown button {string}') do |button_text|
  expect(page).to have_css('.fr-dropdown button', text: button_text)
end

When('I click on the manage dropdown button') do
  find('.fr-dropdown button').click
end

Then('I should see the dropdown action {string}') do |action_text|
  within('.fr-dropdown .fr-dropdown__menu') do
    expect(page).to have_content(action_text)
  end
end

Then('I should see a search field') do
  expect(page).to have_css('input[name="q"]')
end

Then('I should see a filter for {string}') do |filter_label|
  expect(page).to have_css('label', text: filter_label)
end

When('I click on the tab {string}') do |tab_name|
  click_link(tab_name)
end

Then('I should see the buyer section for {string}') do |_key|
  expect(page).to have_content('Acheteur')
end

Then('I should see the candidate section for {string}') do |_key|
  expect(page).to have_content('Candidat')
end

Then('the buyer section should show category information') do
  expect(page).to have_content('Catégorie')
end

Then('the buyer section should show subcategory information') do
  expect(page).to have_content('Sous-catégorie')
end

Then('the attribute {string} should have badge {string}') do |key, badge_text|
  within("[data-testid='market-attribute-#{key}']") do
    expect(page.find(:xpath, './ancestor::section')).to have_css('.fr-badge', text: badge_text)
  end
end

Then('I should see an edit button for {string}') do |key|
  within("[data-testid='market-attribute-#{key}']") do
    expect(page).to have_link('Modifier')
  end
end

Then('I should see the stat card {string} with value {string}') do |card_title, value|
  card = find('.fr-card__title', text: card_title, match: :first).ancestor('.fr-card')
  expect(card).to have_content(value)
end

When('I filter by source {string}') do |source|
  select source, from: 'source'
  find('.fr-search-bar button[type="submit"]').click
end

When('I filter by mandatory {string}') do |mandatory|
  select mandatory, from: 'mandatory'
  find('.fr-search-bar button[type="submit"]').click
end
