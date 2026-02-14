# frozen_string_literal: true

Given('the following ordered market attributes exist:') do |table|
  MarketAttribute.delete_all
  table.hashes.each do |row|
    create(:market_attribute,
      key: row['key'],
      category_key: row['category_key'],
      subcategory_key: row['subcategory_key'],
      position: row['position'].to_i)
  end
end

When('I reorder the socle de base fields as {string}') do |ordered_keys|
  keys = ordered_keys.split(',').map(&:strip)
  ordered_ids = keys.map { |key| MarketAttribute.find_by!(key:).id }

  header 'Content-Type', 'application/json'
  patch reorder_admin_socle_de_base_index_path,
    { ordered_ids: }.to_json
end

Then('the attributes table body should have the drag-reorder controller') do
  expect(page).to have_css('tbody[data-controller="drag-reorder"]')
end

Then('each table row should have a drag handle') do
  rows = all('table tbody tr')
  expect(rows).not_to be_empty
  rows.each do |row|
    expect(row).to have_css('td[data-drag-handle]')
  end
end

Then('the market attribute {string} should have position {int}') do |key, expected_position|
  attribute = MarketAttribute.find_by!(key:)
  expect(attribute.reload.position).to eq(expected_position)
end

Given('the market attribute {string} has position {int}') do |key, position|
  MarketAttribute.find_by!(key:).update!(position:)
end

Then('the market attribute {string} should still belong to category {string}') do |key, category_key|
  attribute = MarketAttribute.find_by!(key:)
  expect(attribute.reload.category_key).to eq(category_key)
end

Then('the first attribute row should be {string}') do |key|
  attribute = MarketAttribute.find_by!(key:)
  first_row = find('table tbody tr:first-child')
  expect(first_row['data-attribute-id']).to eq(attribute.id.to_s)
end

Then('the second attribute row should be {string}') do |key|
  attribute = MarketAttribute.find_by!(key:)
  second_row = all('table tbody tr')[1]
  expect(second_row['data-attribute-id']).to eq(attribute.id.to_s)
end

Then('the third attribute row should be {string}') do |key|
  attribute = MarketAttribute.find_by!(key:)
  third_row = all('table tbody tr')[2]
  expect(third_row['data-attribute-id']).to eq(attribute.id.to_s)
end
