# frozen_string_literal: true

Given('the following categories with labels exist:') do |table|
  table.hashes.each do |row|
    Category.find_or_initialize_by(key: row['key']).update!(
      buyer_label: row['buyer_label'],
      candidate_label: row['candidate_label'],
      position: 0
    )
  end
end

When('I click {string} for category {string}') do |_button_text, key|
  category = Category.find_by!(key:)
  visit edit_admin_category_path(category)
end

When('I submit the edit form for category {string} with:') do |key, table|
  category = Category.find_by!(key:)
  row = table.rows_hash

  page.driver.submit :patch, admin_category_path(category),
    'category[buyer_label]' => row['buyer_label'],
    'category[candidate_label]' => row['candidate_label']
end

Then('I should see the edit category form') do
  expect(page).to have_content('Modifier une catégorie')
end

Then('the buyer label field for category should contain {string}') do |value|
  expect(page).to have_field('category_buyer_label', with: value)
end

Then('the candidate label field for category should contain {string}') do |value|
  expect(page).to have_field('category_candidate_label', with: value)
end

Then('the category {string} buyer label should be {string}') do |key, label|
  expect(Category.find_by!(key:).reload.buyer_label).to eq(label)
end

Then('the category {string} candidate label should be {string}') do |key, label|
  expect(Category.find_by!(key:).reload.candidate_label).to eq(label)
end
