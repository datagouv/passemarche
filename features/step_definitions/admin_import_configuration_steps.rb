# frozen_string_literal: true

Then('I should see the import action in the dropdown') do
  expect(page).to have_content(I18n.t('admin.socle_de_base.actions.import'))
end

When('I import the test CSV file') do
  csv_path = Rails.root.join('spec/fixtures/files/socle_de_base_import.csv')
  page.driver.submit :post, import_admin_socle_de_base_index_path,
    'socle_de_base[csv_file]' => Rack::Test::UploadedFile.new(csv_path, 'text/csv')
  page.driver.follow_redirect! while page.driver.response.redirect?
end

When('I submit the import form without a file') do
  page.driver.submit :post, import_admin_socle_de_base_index_path, {}
  page.driver.follow_redirect! while page.driver.response.redirect?
end

Then('I should see the import success message') do
  expect(page).to have_content('Import réussi')
end

Then('I should see the missing file error') do
  expect(page).to have_content(I18n.t('admin.socle_de_base.import.no_file'))
end
