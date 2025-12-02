# frozen_string_literal: true

require 'webmock/cucumber'

World(FactoryBot::Syntax::Methods)

Given('a public market with file upload field exists') do
  @editor = create(:editor, :authorized_and_active)
  @public_market = create(:public_market, :completed, editor: @editor)

  @file_upload_attr = MarketAttribute.find_or_create_by(key: 'document_naming_test_file') do |attr|
    attr.input_type = 'file_upload'
    attr.category_key = 'technical_capacities'
    attr.subcategory_key = 'documents'
  end
  @file_upload_attr.public_markets << @public_market unless @file_upload_attr.public_markets.include?(@public_market)
end

Given('the file upload field accepts multiple files') do
  # The file_upload input type already supports multiple files by default
  # No additional configuration needed
end

Given('a candidate has started an application') do
  @market_application = create(:market_application,
    public_market: @public_market,
    siret: '73282932000074')

  stub_api_requests
end

When('I visit the documents step') do
  visit "/candidate/market_applications/#{@market_application.identifier}/documents"
end

When('I upload a file {string}') do |filename|
  test_file_path = Rails.root.join("tmp/#{filename}")
  File.write(test_file_path, '%PDF-1.4 fake pdf content for testing')
  page.first('input[type="file"]').attach_file(test_file_path)
end

When('I upload multiple files:') do |table|
  file_input = page.first('input[type="file"]')

  file_paths = []
  table.hashes.each do |row|
    filename = row['filename']
    test_file_path = Rails.root.join("tmp/#{filename}")
    File.write(test_file_path, '%PDF-1.4 fake pdf content')
    file_paths << test_file_path.to_s
  end

  file_input.attach_file(file_paths)
end

When('I complete all remaining steps to reach summary') do
  click_button 'Suivant'

  # Navigate through any remaining steps until we reach summary
  max_attempts = 10
  attempts = 0

  while attempts < max_attempts && current_path.exclude?('summary')
    attempts += 1

    # Fill in any required fields on current step
    fill_in_current_step_fields

    # Try to proceed to next step
    if page.has_button?('Suivant', disabled: false)
      click_button 'Suivant'
    elsif page.has_button?('Continuer', disabled: false)
      click_button 'Continuer'
    else
      break
    end

    sleep 0.2 # Small delay to allow page transitions
  end
end

Then('I should see the original filename {string}') do |filename|
  expect(page).to have_content(filename)
end

Then('I should see the system filename prefix {string}') do |prefix|
  # The system filename format is: prefix_field_key_original_filename
  # e.g., user_01_01_document_naming_test_file_rapport_technique.pdf
  expect(page).to have_content(prefix)
end

Then('I should see the arrow symbol between filenames') do
  # The arrow is now an SVG icon, so we check for the rename-arrow element
  expect(page).to have_css('.rename-arrow')
end

Then('I should see {string} with system prefix {string}') do |original_filename, prefix|
  # Check that both the original filename and system prefix are present in the renamed documents section
  within('.renamed-documents-list') do
    expect(page).to have_content(original_filename)
    expect(page).to have_content(prefix)
    expect(page).to have_css('.rename-arrow')
  end
end

def stub_api_requests
  # Stub INSEE API
  stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v3/insee/sirene/etablissements/.*})
    .to_return(
      status: 200,
      body: {
        data: {
          denomination: 'Test Company',
          category_entreprise: 'PME'
        }
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

  # Stub document downloads
  stub_request(:get, %r{https://.*\.pdf})
    .to_return(
      status: 200,
      body: '%PDF-1.4 test document',
      headers: { 'Content-Type' => 'application/pdf' }
    )
end

def fill_in_current_step_fields
  fill_in_text_fields
  fill_in_email_fields
  fill_in_phone_fields
  fill_in_textarea_fields
  check_all_checkboxes
end

def fill_in_text_fields
  page.all('input[type="text"]').each do |field|
    next if field[:readonly] || field[:disabled] || field[:name]&.include?('siret')

    field.set('Test Value') if field.value.blank?
  end
end

def fill_in_email_fields
  page.all('input[type="email"]').each { |field| field.set('test@example.com') if field.value.blank? }
end

def fill_in_phone_fields
  page.all('input[type="tel"]').each { |field| field.set('01 23 45 67 89') if field.value.blank? }
end

def fill_in_textarea_fields
  page.all('textarea').each { |field| field.set('Test description') if field.value.blank? }
end

def check_all_checkboxes
  page.all('input[type="checkbox"]').each { |checkbox| checkbox.check unless checkbox.checked? }
end

def upload_required_files
  page.all('input[type="file"]').each do |file_input|
    next if file_input[:disabled]

    test_file_path = Rails.root.join('tmp/test_file.pdf')
    File.write(test_file_path, '%PDF-1.4 test content')
    file_input.attach_file(test_file_path)
  end
end
