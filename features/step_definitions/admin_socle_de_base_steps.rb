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

Given('a soft-deleted market attribute {string} exists in {string}') do |key, category_key|
  create(:market_attribute,
    key:,
    category_key:,
    subcategory_key: "#{category_key}_sub",
    deleted_at: Time.current)
end

When('I visit the socle de base page') do
  visit admin_socle_de_base_index_path
end

When('I visit the acheteur categories page') do
  @routing_error = false
  begin
    visit '/admin/acheteur_categories'
  rescue ActionController::RoutingError
    @routing_error = true
  end
end

Then('I should get a routing error') do
  expect(@routing_error || page.status_code == 404).to be true
end

Then('I should see the page title {string}') do |title|
  expect(page).to have_css('h1', text: title)
end

# Category accordion steps

Then('I should see a category accordion for {string}') do |category_key|
  expect(page).to have_css("#accordion-cat-#{category_key}")
end

Then('the category {string} should contain buyer and candidate labels') do |category_key|
  within("#accordion-cat-#{category_key}") do
    expect(page).to have_content('Acheteur')
    expect(page).to have_content('Candidat')
  end
end

Then('the category {string} should contain a {string} link') do |category_key, link_text|
  within("#accordion-cat-#{category_key}") do
    expect(page).to have_link(link_text)
  end
end

Then('the category {string} should contain a subcategory accordion for {string}') do |category_key, subcategory_key|
  within("#accordion-cat-#{category_key}") do
    expect(page).to have_css("#accordion-sub-#{subcategory_key}")
  end
end

# Subcategory accordion steps

Then('the subcategory {string} should contain buyer and candidate labels') do |subcategory_key|
  within("#accordion-sub-#{subcategory_key}") do
    expect(page).to have_content('Acheteur')
    expect(page).to have_content('Candidat')
  end
end

Then('the subcategory {string} should contain a {string} link') do |subcategory_key, link_text|
  within("#accordion-sub-#{subcategory_key}") do
    expect(page).to have_link(link_text)
  end
end

Then('the subcategory {string} should contain a field accordion for {string}') do |subcategory_key, key|
  attribute = MarketAttribute.find_by!(key:)
  within("#accordion-sub-#{subcategory_key}") do
    expect(page).to have_css("#accordion-field-#{attribute.id}")
  end
end

# Field accordion steps

Then('the field {string} should contain buyer and candidate labels') do |key|
  attribute = MarketAttribute.find_by!(key:)
  within("#accordion-field-#{attribute.id}") do
    expect(page).to have_content('Acheteur')
    expect(page).to have_content('Candidat')
  end
end

Then('the field {string} should contain a {string} link') do |key, link_text|
  attribute = MarketAttribute.find_by!(key:)
  within("#accordion-field-#{attribute.id}") do
    expect(page).to have_link(link_text)
  end
end

Then('I should not see a field accordion for {string}') do |key|
  attribute = MarketAttribute.find_by(key:)
  if attribute
    expect(page).not_to have_css("#accordion-field-#{attribute.id}")
  else
    expect(page).not_to have_content(key)
  end
end

# Edit button steps

Then('all {string} links should point to {string}') do |link_text, href|
  links = all('a', text: link_text)
  expect(links).not_to be_empty
  links.each do |link|
    expect(link[:href]).to end_with(href)
  end
end

# UI component steps

Then('I should see the manage dropdown button {string}') do |button_text|
  expect(page).to have_css('.fr-dropdown button', text: button_text)
end

Then('I should see the stat card {string} with value {string}') do |card_title, value|
  card = find('.fr-card__title', text: card_title, match: :first).ancestor('.fr-card')
  expect(card).to have_content(value)
end
