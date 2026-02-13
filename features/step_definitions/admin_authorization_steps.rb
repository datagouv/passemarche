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

Then('I should not see the add editor button') do
  expect(page).not_to have_link(I18n.t('admin.editors.index.add'))
end

Then('I should see the add editor button') do
  expect(page).to have_link(I18n.t('admin.editors.index.add'))
end

Then('I should be redirected to the admin root') do
  expect(page).to have_current_path(admin_root_path)
end

Then('I should see a permission denied message') do
  expect(page).to have_content(I18n.t('admin.authorization.insufficient_permissions'))
end

Then('I should not see edit and delete buttons') do
  expect(page).not_to have_link(I18n.t('admin.shared.edit'))
  expect(page).not_to have_link(I18n.t('admin.shared.delete'))
end

Then('I should see edit and delete buttons') do
  expect(page).to have_link(I18n.t('admin.shared.edit'))
  expect(page).to have_link(I18n.t('admin.shared.delete'))
end
