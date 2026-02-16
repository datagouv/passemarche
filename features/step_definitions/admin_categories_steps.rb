# frozen_string_literal: true

Given('the following categories exist:') do |table|
  Category.delete_all
  table.hashes.each do |row|
    create(:category,
      key: row['key'],
      buyer_label: row['buyer_label'],
      candidate_label: row['candidate_label'],
      position: row['position'].to_i)
  end
end

Given('the following subcategories exist:') do |table|
  Subcategory.delete_all
  table.hashes.each do |row|
    category = Category.find_by!(key: row['category_key'])
    create(:subcategory,
      key: row['key'],
      buyer_label: row['buyer_label'],
      candidate_label: row['candidate_label'],
      category:,
      position: row['position'].to_i)
  end
end

Given('a soft-deleted category {string} exists') do |buyer_label|
  create(:category, buyer_label:, deleted_at: Time.current)
end

Given('a soft-deleted subcategory {string} exists') do |buyer_label|
  category = Category.first || create(:category)
  create(:subcategory, buyer_label:, category:, deleted_at: Time.current)
end

When('I visit the categories page') do
  visit admin_categories_path
end

When('I reorder categories as {string}') do |ordered_keys|
  keys = ordered_keys.split(',').map(&:strip)
  ordered_ids = keys.map { |key| Category.find_by!(key:).id }

  header 'Content-Type', 'application/json'
  patch reorder_admin_categories_path,
    { ordered_ids: }.to_json
end

When('I reorder subcategories as {string}') do |ordered_keys|
  keys = ordered_keys.split(',').map(&:strip)
  ordered_ids = keys.map { |key| Subcategory.find_by!(key:).id }

  header 'Content-Type', 'application/json'
  patch reorder_admin_subcategories_path,
    { ordered_ids: }.to_json
end

Then('I should see a categories table with headers {string}, {string}, {string}') do |*headers|
  within('#categories-table thead') do
    headers.each { |h| expect(page).to have_css('th', text: h) }
  end
end

Then('I should see a subcategories table with headers {string}, {string}, {string}') do |*headers|
  within('#subcategories-table thead') do
    headers.each { |h| expect(page).to have_css('th', text: h) }
  end
end

Then('the categories table should display {string} and {string}') do |buyer, candidate|
  within('#categories-table') do
    expect(page).to have_content(buyer)
    expect(page).to have_content(candidate)
  end
end

Then('the subcategories table should display {string} and {string}') do |buyer, candidate|
  within('#subcategories-table') do
    expect(page).to have_content(buyer)
    expect(page).to have_content(candidate)
  end
end

Then('each category row should have a {string} button') do |text|
  within('#categories-table tbody') do
    all('tr').each { |row| expect(row).to have_link(text) }
  end
end

Then('each subcategory row should have a {string} button') do |text|
  within('#subcategories-table tbody') do
    all('tr').each { |row| expect(row).to have_link(text) }
  end
end

Then('I should see the {string} dropdown button') do |text|
  expect(page).to have_css('.fr-dropdown button', text:)
end

Then('the create dropdown should contain {string}') do |text|
  within('.fr-dropdown') do
    expect(page).to have_content(text)
  end
end

Then('each category row should have a drag handle') do
  within('#categories-table tbody') do
    all('tr').each { |row| expect(row).to have_css('td[data-drag-handle]') }
  end
end

Then('each subcategory row should have a drag handle') do
  within('#subcategories-table tbody') do
    all('tr').each { |row| expect(row).to have_css('td[data-drag-handle]') }
  end
end

Then('the category {string} should have position {int}') do |key, position|
  expect(Category.find_by!(key:).reload.position).to eq(position)
end

Then('the category {string} should still have position {int}') do |key, position|
  expect(Category.find_by!(key:).reload.position).to eq(position)
end

Then('the subcategory {string} should have position {int}') do |key, position|
  expect(Subcategory.find_by!(key:).reload.position).to eq(position)
end

Then('the manage dropdown should contain a link to the categories page') do
  within('.fr-dropdown') do
    expect(page).to have_link(href: admin_categories_path)
  end
end

Then('I should see a back link to the Socle de Base page') do
  expect(page).to have_link(href: admin_socle_de_base_index_path)
end

Then('I should not see {string} in the categories table') do |text|
  within('#categories-table') do
    expect(page).not_to have_content(text)
  end
end

Then('I should not see {string} in the subcategories table') do |text|
  within('#subcategories-table') do
    expect(page).not_to have_content(text)
  end
end
