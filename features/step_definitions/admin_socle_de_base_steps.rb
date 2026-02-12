# frozen_string_literal: true

Given('the following market types exist:') do |table|
  table.hashes.each do |row|
    MarketType.find_or_create_by!(code: row['code'])
  end
end

Given('the following market attributes exist:') do |table|
  MarketAttribute.delete_all
  table.hashes.each do |row|
    attr = create(:market_attribute,
      key: row['key'],
      category_key: row['category_key'],
      subcategory_key: row['subcategory_key'],
      mandatory: row['mandatory'] == 'true',
      api_name: row['api_name'].presence,
      api_key: row['api_name'].present? ? 'test_key' : nil)

    next if row['market_types'].blank?

    codes = row['market_types'].split(',').map(&:strip)
    codes.each do |code|
      market_type = MarketType.find_by!(code:)
      attr.market_types << market_type
    end
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

Then('I should see the page title {string}') do |title|
  expect(page).to have_css('h1', text: title)
end

# Table structure steps

Then('I should see a table with headers {string}, {string}, {string}, {string}, {string}, {string}') do |*headers|
  within('table thead') do
    headers.each do |header|
      expect(page).to have_css('th', text: header)
    end
  end
end

Then('I should see {int} rows in the attributes table') do |count|
  expect(page).to have_css('table tbody tr', count:)
end

# Market type badge steps

Then('the row for {string} should have all market type badges active') do |key|
  attribute = MarketAttribute.find_by!(key:)
  within("tr[data-attribute-id='#{attribute.id}']") do
    expect(page).to have_css('.fr-badge--blue-cumulus', count: 3)
  end
end

Then('the row for {string} should have only {string} badge active') do |key, badge_letter|
  attribute = MarketAttribute.find_by!(key:)
  within("tr[data-attribute-id='#{attribute.id}']") do
    expect(page).to have_css('.fr-badge--blue-cumulus', count: 1, text: badge_letter)
  end
end

Then('the row for {string} should have no market type badges active') do |key|
  attribute = MarketAttribute.find_by!(key:)
  within("tr[data-attribute-id='#{attribute.id}']") do
    expect(page).to have_no_css('.fr-badge--blue-cumulus')
  end
end

# Source column steps

Then('the row for {string} should show source {string}') do |key, source_text|
  attribute = MarketAttribute.find_by!(key:)
  within("tr[data-attribute-id='#{attribute.id}']") do
    expect(page).to have_css('.fr-badge', text: source_text)
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

# Soft delete steps

Then('I should not see a row for {string}') do |key|
  attribute = MarketAttribute.find_by(key:)
  if attribute
    expect(page).to have_no_css("tr[data-attribute-id='#{attribute.id}']")
  else
    expect(page).not_to have_content(key)
  end
end

# Drag handle steps

Then('each table row should have a drag handle icon') do
  rows = all('table tbody tr')
  expect(rows).not_to be_empty
  rows.each do |row|
    expect(row).to have_css('svg.drag-handle-icon')
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
