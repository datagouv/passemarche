# frozen_string_literal: true

When('I click the export link in the manage dropdown') do
  click_on 'Gérer le socle de base'
  click_on 'Exporter'
end

Then('I should receive a CSV file with the correct filename') do
  expect(page.response_headers['Content-Type']).to include('text/csv')
  expect(page.response_headers['Content-Disposition']).to include("socle-de-base-#{Date.current}.csv")
end

Then('the CSV should contain the correct headers') do
  csv = CSV.parse(page.body, col_sep: ';', headers: true)
  expect(csv.headers).to include('Clé', 'Catégorie (clé)', 'Catégorie acheteur', 'Obligatoire',
    'Source (api_name)', 'Types de marché')
end

Then('the CSV should contain {int} data rows') do |count|
  csv = CSV.parse(page.body, col_sep: ';', headers: true)
  expect(csv.count).to eq(count)
end

When('I export the socle de base with category filter {string}') do |category|
  visit export_admin_socle_de_base_index_path(category:)
end

Then('the CSV should contain a row with key {string}') do |key|
  csv = CSV.parse(page.body, col_sep: ';', headers: true)
  keys = csv.map { |row| row['Clé'] } # rubocop:disable Rails/Pluck
  expect(keys).to include(key)
end

Then('the CSV should not contain a row with key {string}') do |key|
  csv = CSV.parse(page.body, col_sep: ';', headers: true)
  keys = csv.map { |row| row['Clé'] } # rubocop:disable Rails/Pluck
  expect(keys).not_to include(key)
end

When('I request the socle de base export') do
  visit export_admin_socle_de_base_index_path
end
