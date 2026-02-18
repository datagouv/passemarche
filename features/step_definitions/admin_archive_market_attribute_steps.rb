# frozen_string_literal: true

Then('I should see an archive button for {string}') do |key|
  attribute = MarketAttribute.find_by!(key:)
  within("tr[data-item-id='#{attribute.id}']") do
    expect(page).to have_button('Archiver')
  end
end

When('I archive the field {string}') do |key|
  attribute = MarketAttribute.find_by!(key:)
  visit admin_socle_de_base_index_path
  within("tr[data-item-id='#{attribute.id}']") do
    click_button 'Archiver'
  end
end

Then('I should see a success flash message containing {string}') do |text|
  expect(page).to have_content(text)
end

Then('the field {string} should still exist in the database') do |key|
  expect(MarketAttribute.unscoped.find_by(key:)).to be_present
end

Then('the field {string} should have a deleted_at timestamp') do |key|
  attribute = MarketAttribute.unscoped.find_by!(key:)
  expect(attribute.deleted_at).to be_present
end

Given('I am not logged in') do
  Warden.test_reset!
end

When('I attempt to archive the field {string} without authentication') do |key|
  attribute = MarketAttribute.find_by!(key:)
  page.driver.submit :patch, archive_admin_socle_de_base_path(attribute), {}
end

Then('I should be redirected to the login page') do
  expect(page).to have_current_path(new_admin_user_session_path)
end
