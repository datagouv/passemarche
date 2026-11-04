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
  authenticate_as_candidate_for(@market_application)

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
  submit_step
  navigate_to_summary
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

def upload_required_files
  attach_test_files_to_all_inputs('test_file.pdf')
end
