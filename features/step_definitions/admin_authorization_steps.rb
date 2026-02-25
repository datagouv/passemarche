# frozen_string_literal: true

Given('I am logged in as a lecteur user') do
  @admin_user = create(:admin_user, :lecteur)
  login_as(@admin_user, scope: :admin_user)
end

When('I visit the admin editors page') do
  visit admin_editors_path
end

When('I try to access the new editor page') do
  visit new_admin_editor_path
end

When('I try to access the new socle de base page') do
  visit new_admin_socle_de_base_path
end

When('I visit the socle de base detail page for {string}') do |key|
  attribute = MarketAttribute.find_by!(key:)
  visit admin_socle_de_base_path(attribute)
end

When('I try to access the edit category page for {string}') do |key|
  category = Category.find_by!(key:)
  visit edit_admin_category_path(category)
end

When('I try to access the edit subcategory page for {string}') do |key|
  subcategory = Subcategory.find_by!(key:)
  visit edit_admin_subcategory_path(subcategory)
end

Then('I should be redirected to the admin root') do
  expect(page).to have_current_path(admin_root_path)
end

Then('I should see a permission denied message') do
  expect(page).to have_content(I18n.t('admin.authorization.insufficient_permissions'))
end

# --- Editors ---

Then('I should see a disabled add editor button') do
  expect(page).to have_button(I18n.t('admin.editors.index.add'), disabled: true)
end

Then('I should see an enabled add editor button') do
  expect(page).to have_link(I18n.t('admin.editors.index.add'))
end

Then('I should see disabled edit and delete buttons') do
  expect(page).to have_button(I18n.t('admin.shared.edit'), disabled: true)
  expect(page).to have_button(I18n.t('admin.shared.delete'), disabled: true)
end

Then('I should see enabled edit and delete buttons') do
  expect(page).to have_link(I18n.t('admin.shared.edit'))
  expect(page).to have_link(I18n.t('admin.shared.delete'))
end

# --- Socle de base ---

Then('I should see a disabled import button') do
  expect(page).to have_button(I18n.t('admin.socle_de_base.actions.import'), disabled: true)
end

Then('I should see a disabled new field button') do
  expect(page).to have_button(I18n.t('admin.socle_de_base.actions.new_field'), disabled: true)
end

Then('I should see a disabled archive button for the field') do
  expect(page).to have_button(I18n.t('admin.socle_de_base.archive_button'), disabled: true)
end

Then('I should see a disabled archive button') do
  expect(page).to have_button(I18n.t('admin.socle_de_base.show.archive_button'), disabled: true)
end

Then('I should see a disabled edit button') do
  expect(page).to have_button(I18n.t('admin.socle_de_base.edit.title'), disabled: true)
end

# --- Categories ---

Then('I should see a disabled create dropdown button') do
  expect(page).to have_button(I18n.t('admin.categories.actions.create'), disabled: true)
end

Then('I should see disabled edit buttons for categories') do
  within('#categories-table') do
    expect(page).to have_button(I18n.t('admin.categories.actions.edit'), disabled: true)
  end
end

Then('I should see disabled edit buttons for subcategories') do
  within('#subcategories-table') do
    expect(page).to have_button(I18n.t('admin.categories.actions.edit'), disabled: true)
  end
end
