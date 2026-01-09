# frozen_string_literal: true

Given('I am logged in as an admin user') do
  @admin_user = create(:admin_user)
  login_as(@admin_user, scope: :admin_user)
end

Given('the following editors exist:') do |table|
  table.hashes.each do |row|
    create(:editor,
      name: row['name'],
      authorized: row['authorized'] == 'true',
      active: row['active'] == 'true')
  end
end

Given('{string} has {int} public market(s)') do |editor_name, count|
  editor = Editor.find_by!(name: editor_name)
  count.times do
    create(:public_market, :completed, editor:)
  end
end

Given('{string} has {int} completed market application(s)') do |editor_name, count|
  editor = Editor.find_by!(name: editor_name)
  count.times do
    market = editor.public_markets.first || create(:public_market, :completed, editor:)
    create(:market_application, :completed, public_market: market)
  end
end

When('I visit the admin dashboard') do
  visit admin_dashboard_path
end

When('I visit the admin dashboard filtered by {string}') do |editor_name|
  editor = Editor.find_by!(name: editor_name)
  visit admin_dashboard_path(editor_id: editor.id)
end

When('I visit the admin editor page for {string}') do |editor_name|
  editor = Editor.find_by!(name: editor_name)
  visit admin_editor_path(editor)
end

When('I select {string} from the editor filter') do |editor_name|
  select editor_name, from: 'editor_id'
end

When('I click on the admin link {string}') do |link_text|
  click_on link_text
end

Then('I should see {string} on the page') do |text|
  expect(page).to have_content(text)
end

Then('I should see the statistic {string} with value {string}') do |metric_label, value|
  # Find the card whose title contains the metric label and check the value is present
  card = find('.fr-card__title', text: /#{Regexp.escape(metric_label)}/i, match: :first).ancestor('.fr-card')
  expect(card).to have_content(value)
end

Then('I should receive a CSV file named {string}') do |filename_pattern|
  expect(page.response_headers['Content-Type']).to include('text/csv')
  expect(page.response_headers['Content-Disposition']).to include(filename_pattern)
end
