# frozen_string_literal: true

require 'webmock/cucumber'

World(FactoryBot::Syntax::Methods)

Given('a comprehensive public market with all input types exists') do
  @editor = create(:editor, :authorized_and_active)
  @public_market = create(:public_market, :completed, editor: @editor)

  [
    { key: :comprehensive_test_email, input_type: 'email_input', category_key: 'identite_entreprise', subcategory_key: 'contact', mandatory: true },
    { key: :comprehensive_test_phone, input_type: 'phone_input', category_key: 'identite_entreprise', subcategory_key: 'contact', mandatory: true },
    { key: :comprehensive_test_company_name, input_type: 'text_input', category_key: 'identite_entreprise', subcategory_key: 'identification', mandatory: true },
    { key: :comprehensive_test_exclusion, input_type: 'checkbox_with_document', category_key: 'exclusion_criteria', subcategory_key: 'declarations', mandatory: true },
    { key: :comprehensive_test_economic, input_type: 'textarea', category_key: 'economic_capacities', subcategory_key: 'description', mandatory: true },
    { key: :comprehensive_test_technical, input_type: 'file_upload', category_key: 'technical_capacities', subcategory_key: 'documents', mandatory: true },
    { key: :comprehensive_test_checkbox_doc, input_type: 'checkbox_with_document', category_key: 'technical_capacities', subcategory_key: 'attestations', mandatory: false },
    { key: :comprehensive_test_certifications, input_type: 'checkbox_with_document', category_key: 'technical_capacities', subcategory_key: 'certifications', mandatory: true },
    { key: :capacite_economique_financiere_chiffre_affaires_global_annuel, input_type: 'capacite_economique_financiere_chiffre_affaires_global_annuel',
      category_key: 'capacite_economique_financiere', subcategory_key: 'capacite_economique_financiere_chiffre_affaires',
      mandatory: false, api_name: 'dgfip_chiffres_affaires', api_key: 'chiffres_affaires_data' }
  ].each_with_index do |attrs, index|
    key = attrs.delete(:key)
    attr = create(:market_attribute, key: "#{key}_#{@public_market.id}", position: index + 1, **attrs)
    @public_market.market_attributes << attr
  end
end

Given('a candidate starts a comprehensive application') do
  @market_application = create(:market_application, public_market: @public_market, siret: '73282932000074')
  authenticate_as_candidate_for(@market_application)
  stub_comprehensive_api_requests
end

Given('a market with checkbox_with_document fields exists') do
  @editor = create(:editor, :authorized_and_active)
  @public_market = create(:public_market, :completed, editor: @editor)
  attr = MarketAttribute.find_or_create_by(key: 'comprehensive_test_checkbox_document') do |a|
    a.input_type = 'checkbox_with_document'
    a.category_key = 'technical_capacities'
    a.subcategory_key = 'certifications'
    a.mandatory = true
  end
  @public_market.market_attributes << attr unless @public_market.market_attributes.include?(attr)
  @market_application = create(:market_application, public_market: @public_market, siret: '73282932000074')
  authenticate_as_candidate_for(@market_application)
end

When('I visit the checkbox with document step') do
  visit "/candidate/market_applications/#{@market_application.identifier}/certifications"
end

Then('I should see a checkbox and file upload combined') do
  expect(page).to have_css('input[type="checkbox"]')
  expect(page).to have_css('input[type="file"]')
end

When('I check the checkbox') do
  page.find('input[type="checkbox"]').check
end

When('I upload a document') do
  test_file_path = Rails.root.join('tmp/test_document.pdf')
  File.write(test_file_path, '%PDF-1.4 fake pdf content')
  page.all('input[type="file"]').first.attach_file(test_file_path)
end

Then('I should see API names list') do
  expect(page).to have_content('Nous récupérons vos documents et informations')
end

When('all APIs complete successfully') do
  @market_application.update!(api_fetch_status: completed_api_status)
  visit current_path
  expect(page).to have_button('Continuer', disabled: false, wait: 10)
end

Given('I have filled all required fields across all steps') do
  visit "/candidate/market_applications/#{@market_application.identifier}/company_identification"
  click_button 'Continuer'
  @market_application.update!(api_fetch_status: completed_api_status)
  visit current_path
  expect(page).to have_button('Continuer', disabled: false, wait: 10)
  click_button 'Continuer'

  step('I click "Suivant"')
  step('I fill in contact fields with valid data')
  step('I click "Suivant"')
  step('I fill in identification fields with valid data')
  step('I click "Suivant"')
  step('I check the required exclusion checkboxes')
  step('I click "Suivant"')
  step('I fill in the economic capacity information')
  step('I click "Suivant"')
  step('I upload required documents')
  step('I click "Suivant"')
  step('I handle optional checkbox with document')
  step('I click "Suivant"')
  step('I handle optional checkbox with document')
  step('I click "Suivant"')
  step('I fill in the turnover percentages')
  step('I click "Suivant"')
end

When('I upload a valid document {string}') do |filename|
  attach_test_file(filename)
end

When('I leave the required file upload empty') do
  # Don't upload — triggers validation errors for required file upload
end

Then('I should see {string} in the uploaded files') do |filename|
  expect(page).to have_content(filename)
end

Then('the document should not have a download link') do
  expect(page).not_to have_link(href: %r{rails/active_storage})
end

Then('I should see {string} with a download link') do |filename|
  expect(page).to have_css('a[href*="rails/active_storage"]')
  raise "Expected to see '#{filename}' but found neither it nor fallback file" unless page.has_content?(filename) || page.has_content?('test_upload.pdf')

  true
end

When('I upload multiple valid documents:') do |table|
  fill_in_all_available_fields
  file_paths = table.hashes.map do |row|
    path = Rails.root.join("tmp/#{row['filename']}")
    content = case row['content_type']
              when 'application/pdf' then '%PDF-1.4 fake pdf content'
              when 'image/jpeg', 'image/jpg' then 'fake jpeg content'
              when 'image/png' then 'fake png content'
              else 'fake file content'
              end
    File.write(path, content)
    path.to_s
  end
  page.first('input[type="file"]').attach_file(file_paths)
end

Then('I should see all uploaded documents:') do |table|
  table.hashes.each { |row| expect(page).to have_content(row['filename']) }
end

Then('each document should have a download link') do
  expect(page).to have_css('a[href*="rails/active_storage"]')
end

When('I attempt to upload an invalid file {string}') do |filename|
  path = Rails.root.join("tmp/#{filename}")
  File.write(path, 'invalid text file content')
  page.first('input[type="file"]').attach_file(path)
end

Then('I should see {string} message') do |message|
  expect(page).to have_content(message)
end

Then('I should not see {string} text') do |text|
  expect(page).not_to have_content(text)
end

def fill_in_all_available_fields
  fill_in_visible_fields
  attach_test_files_to_all_inputs
end

def completed_api_status
  {
    'insee' => { 'status' => 'completed', 'fields_filled' => 5 },
    'rne' => { 'status' => 'completed', 'fields_filled' => 3 },
    'attestations_fiscales' => { 'status' => 'completed', 'fields_filled' => 2 },
    'probtp' => { 'status' => 'completed', 'fields_filled' => 1 },
    'qualibat' => { 'status' => 'completed', 'fields_filled' => 0 },
    'dgfip_chiffres_affaires' => { 'status' => 'completed', 'fields_filled' => 1 }
  }
end

def stub_comprehensive_api_requests
  stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v3/insee/sirene/etablissements/73282932000074.*})
    .to_return(status: 200, body: { data: { denomination: 'Test Company Comprehensive', category_entreprise: 'PME' } }.to_json, headers: { 'Content-Type' => 'application/json' })

  stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v3/inpi/rne/unites_legales/.*/extrait_rne})
    .to_return(status: 200, body: { data: { document_url: 'https://example.com/rne.pdf' } }.to_json, headers: { 'Content-Type' => 'application/json' })

  stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v4/qualibat/etablissements/.*/certification_batiment})
    .to_return(status: 200, body: { data: { document_url: 'https://qualibat.example.com/cert.pdf' } }.to_json, headers: { 'Content-Type' => 'application/json' })

  stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v4/dgfip/unites_legales/.*/attestation_fiscale})
    .to_return(status: 200, body: { data: { document_url: 'https://storage.exemple.com/dgfip.pdf' } }.to_json, headers: { 'Content-Type' => 'application/json' })

  stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v3/dgfip/etablissements/.*/chiffres_affaires})
    .to_return(status: 200, body: { data: [
      { data: { chiffre_affaires: 500_000.0, date_fin_exercice: '2023-12-31' } },
      { data: { chiffre_affaires: 450_000.0, date_fin_exercice: '2022-12-31' } },
      { data: { chiffre_affaires: 400_000.0, date_fin_exercice: '2021-12-31' } }
    ] }.to_json, headers: { 'Content-Type' => 'application/json' })

  stub_request(:get, %r{https://.*\.pdf})
    .to_return(status: 200, body: '%PDF-1.4 test document', headers: { 'Content-Type' => 'application/pdf' })
end
