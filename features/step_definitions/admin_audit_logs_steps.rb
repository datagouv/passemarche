# frozen_string_literal: true

Then('I should see the history link in the dropdown') do
  expect(page).to have_link(I18n.t('admin.socle_de_base.actions.history'), href: admin_audit_logs_path)
end

When('I visit the audit logs page') do
  visit admin_audit_logs_path
end

When('I visit the audit logs page with no prior versions') do
  PaperTrail::Version.delete_all
  visit admin_audit_logs_path
end

Given('audit log entries exist for market attribute changes') do
  PaperTrail.request.whodunnit = @admin_user.id
  @tracked_attribute = create(:market_attribute,
    category_key: 'identite_entreprise',
    subcategory_key: 'identite_entreprise_identification',
    buyer_name: 'SIRET acheteur',
    candidate_name: 'SIRET candidat')
end

Given('a modification audit log entry exists') do
  PaperTrail::Version.delete_all
  PaperTrail.request.whodunnit = @admin_user.id
  @tracked_attribute = create(:market_attribute,
    buyer_name: 'Ancien titre',
    candidate_name: 'Ancien candidat')
  @tracked_attribute.update!(buyer_name: 'Nouveau titre')
end

Then('I should see audit log entries in the table') do
  expect(page).to have_css('table tbody tr')
end

Then('I should see {string} in the audit logs table') do |text|
  within('table') do
    expect(page).to have_content(text)
  end
end

When('I filter audit logs by text {string}') do |query|
  fill_in 'query', with: query
  click_button I18n.t('admin.audit_logs.filters.submit')
end

When("I filter audit logs by today's date range") do
  fill_in 'date_from', with: Date.current.to_s
  fill_in 'date_to', with: Date.current.to_s
  click_button I18n.t('admin.audit_logs.filters.submit')
end

Then('I should see filtered audit log results') do
  expect(page).to have_css('table tbody tr')
end

When('I click {string} for the first audit log entry') do |link_text|
  within('table tbody tr:first-child') do
    click_link link_text
  end
end

Then('I should see the modification details') do
  expect(page).to have_content(I18n.t('admin.audit_logs.show.title'))
  expect(page).to have_content('Modification')
end

Then('I should see the creation details') do
  expect(page).to have_content(I18n.t('admin.audit_logs.show.title'))
  expect(page).to have_content('Création')
end

Given('I am not logged in as admin') do
  Warden.test_reset!
end

When('I try to visit the audit logs page') do
  visit admin_audit_logs_path
end

Then('I should be redirected to the admin login page') do
  expect(page).to have_current_path(new_admin_user_session_path)
end
