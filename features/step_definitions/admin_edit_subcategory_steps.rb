# frozen_string_literal: true

When('I click {string} for subcategory {string}') do |_button_text, key|
  subcategory = Subcategory.find_by!(key:)
  visit edit_admin_subcategory_path(subcategory)
end

When('I submit the edit form for subcategory {string} with:') do |key, table|
  subcategory = Subcategory.find_by!(key:)
  row = table.rows_hash
  category = Category.find_by!(key: row['category_key'])

  page.driver.submit :patch, admin_subcategory_path(subcategory),
    'subcategory[buyer_label]' => row['buyer_label'],
    'subcategory[candidate_label]' => row['candidate_label'],
    'subcategory[category_id]' => category.id.to_s
end

Then('I should see the edit subcategory form') do
  expect(page).to have_content('Modifier une sous catégorie')
end

Then('the buyer label field should contain {string}') do |value|
  expect(page).to have_field('subcategory_buyer_label', with: value)
end

Then('the candidate label field should contain {string}') do |value|
  expect(page).to have_field('subcategory_candidate_label', with: value)
end

Then('the subcategory {string} buyer label should be {string}') do |key, label|
  expect(Subcategory.find_by!(key:).reload.buyer_label).to eq(label)
end

Then('the subcategory {string} candidate label should be {string}') do |key, label|
  expect(Subcategory.find_by!(key:).reload.candidate_label).to eq(label)
end

Then('the subcategory {string} should belong to category {string}') do |sub_key, cat_key|
  subcategory = Subcategory.find_by!(key: sub_key)
  category = Category.find_by!(key: cat_key)
  expect(subcategory.reload.category).to eq(category)
end

Then('I should see a validation error') do
  expect(page.driver.response.status).to eq(422)
end
