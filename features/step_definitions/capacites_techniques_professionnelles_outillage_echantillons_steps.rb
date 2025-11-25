# frozen_string_literal: true

World(FactoryBot::Syntax::Methods)

# Background steps
Given('a public market with capacites_techniques_professionnelles_outillage_echantillons field exists') do
  @editor = create(:editor, :authorized_and_active)
  @public_market = create(:public_market, :completed, editor: @editor)

  @echantillons_attr = MarketAttribute.find_or_initialize_by(
    key: 'capacites_techniques_professionnelles_outillage_echantillons'
  )
  @echantillons_attr.assign_attributes(
    input_type: 'capacites_techniques_professionnelles_outillage_echantillons',
    category_key: 'capacites_techniques_professionnelles',
    subcategory_key: 'capacites_techniques_professionnelles_outillage',
    required: true
  )
  @echantillons_attr.save!
  @echantillons_attr.public_markets << @public_market unless @echantillons_attr.public_markets.include?(@public_market)

  # Verify the attribute is required for this test
  raise 'MarketAttribute not properly configured' unless @echantillons_attr.reload.required?
end

Given('a candidate starts an application for this echantillons market') do
  @market_application = create(:market_application,
    public_market: @public_market,
    siret: '73282932000074')
end

# Navigation steps
When('I visit the echantillons step') do
  visit "/candidate/market_applications/#{@market_application.identifier}/capacites_techniques_professionnelles_outillage"
end

When('I navigate back to the echantillons step') do
  visit "/candidate/market_applications/#{@market_application.identifier}/capacites_techniques_professionnelles_outillage"
end

# Display verification steps
Then('I should see the echantillons {string} button') do |button_text|
  expect(page).to have_button(button_text)
end

Then('the echantillons page should have a nested-form controller for dynamic fields') do
  expect(page).to have_css('[data-controller="nested-form"]')
  expect(page).to have_css('template[data-nested-form-target="template"]', visible: false)
end

Then('the echantillons page should have a button to add echantillons dynamically') do
  expect(page).to have_css('button[data-action="nested-form#add"]')
end

# Form submission steps (non-JavaScript)
Given('I have submitted single echantillon data:') do |table|
  row = table.hashes.first
  timestamp = Time.now.to_i.to_s

  page.driver.submit :patch, "/candidate/market_applications/#{@market_application.identifier}/capacites_techniques_professionnelles_outillage",
    market_application: {
      market_attribute_responses_attributes: {
        '0' => {
          id: '',
          market_attribute_id: @echantillons_attr.id.to_s,
          type: 'CapacitesTechniquesProfessionnellesOutillageEchantillons',
          "echantillon_#{timestamp}_description" => row['description']
        }
      }
    }
end

Given('I have submitted echantillons data with multiple items:') do |table|
  base_timestamp = Time.now.to_i
  responses_attrs = {}

  table.hashes.each_with_index do |row, index|
    timestamp = (base_timestamp + index).to_s
    responses_attrs["echantillon_#{timestamp}_description"] = row['description']
  end

  page.driver.submit :patch, "/candidate/market_applications/#{@market_application.identifier}/capacites_techniques_professionnelles_outillage",
    market_application: {
      market_attribute_responses_attributes: {
        '0' => {
          id: '',
          market_attribute_id: @echantillons_attr.id.to_s,
          type: 'CapacitesTechniquesProfessionnellesOutillageEchantillons'
        }.merge(responses_attrs)
      }
    }
end

When('I submit échantillon without description') do
  # Directly create the échantillon with a file but no description via the model
  # This tests the validation logic without involving the complex JavaScript file upload UI
  response = MarketAttributeResponse::CapacitesTechniquesProfessionnellesOutillageEchantillons.find_or_create_by!(
    market_application: @market_application,
    market_attribute: @echantillons_attr
  )

  timestamp = Time.now.to_i.to_s

  # Create and attach a real file
  file_path = Rails.root.join('spec/fixtures/files/test.pdf')
  file = fixture_file_upload(file_path, 'application/pdf')
  response.attach_specialized_document(timestamp, 'fichiers', file)
  response.set_item_field(timestamp, 'fichiers', 'attached')
  # Intentionally NOT setting description to trigger validation error
  response.save!(validate: false) # Save without validation to persist the invalid state

  # Visit the step page which will load the invalid data
  visit "/candidate/market_applications/#{@market_application.identifier}/capacites_techniques_professionnelles_outillage"

  # Try to move to next step - this should fail validation and stay on same page with error
  click_button 'Suivant'
end

Then('I should see échantillon validation error {string}') do |error_text|
  expect(page).to have_content(error_text)
end

# Data verification steps
Then('the echantillon data should be saved correctly') do
  @market_application.reload
  response = @market_application.market_attribute_responses.last
  expect(response).to be_present
  expect(response.class.name).to eq('MarketAttributeResponse::CapacitesTechniquesProfessionnellesOutillageEchantillons')

  echantillons = response.echantillons.values.compact
  expect(echantillons.length).to eq(1)

  first_echantillon = echantillons.first
  expect(first_echantillon['description']).to eq('Échantillon de mobilier urbain conforme aux normes PMR, acier inoxydable')
end

Then('both echantillons data should be saved correctly') do
  @market_application.reload
  response = @market_application.market_attribute_responses.last
  expect(response).to be_present
  expect(response.echantillons.length).to eq(2)

  echantillons = response.echantillons.values.sort_by { |e| e['description'] }
  expect(echantillons[0]['description']).to eq('Prototype de signalétique conforme PMR')
  expect(echantillons[1]['description']).to eq('Échantillon de mobilier urbain acier inoxydable')
end

Then('only echantillon {int} data should be saved') do |_echantillon_number|
  @market_application.reload
  response = @market_application.market_attribute_responses.last
  expect(response).to be_present

  echantillons = response.echantillons.values.compact
  expect(echantillons.length).to eq(1)

  first_echantillon = echantillons.first
  expect(first_echantillon['description']).to eq('Prototype de signalétique PMR')
end

# Background data setup for summary tests
Given('I have submitted echantillon data:') do |table|
  row = table.hashes.first
  response = MarketAttributeResponse::CapacitesTechniquesProfessionnellesOutillageEchantillons.create!(
    market_application: @market_application,
    market_attribute: @echantillons_attr
  )

  timestamp = Time.now.to_i.to_s
  response.set_item_field(timestamp, 'description', row['description'])
  response.save!
  @saved_timestamp = timestamp
end

# Summary display verification
Then('I should see the echantillons data displayed:') do |table|
  table.hashes.each do |row|
    expect(page).to have_content(row['echantillon'])
    expect(page).to have_content(row['description'])
  end
end

# Data persistence verification
Then('the saved echantillon data should be displayed in the form') do
  @market_application.reload
  response = @market_application.market_attribute_responses.last
  expect(response).to be_present
  expect(response.echantillons).not_to be_empty

  echantillon_data = response.echantillons.values.compact.first
  expect(page).to have_field(type: 'textarea', with: echantillon_data['description'])
end

# Empty state tests
When('I click {string} without adding any échantillons') do |button_text|
  click_button(button_text)
end

Then('I should see {string} in the echantillons summary') do |text|
  expect(page).to have_content(text)
end

# File upload tests
Given('I have an échantillon with fichiers:') do |table|
  row = table.hashes.first
  response = MarketAttributeResponse::CapacitesTechniquesProfessionnellesOutillageEchantillons.create!(
    market_application: @market_application,
    market_attribute: @echantillons_attr
  )

  timestamp = Time.now.to_i.to_s
  response.set_item_field(timestamp, 'description', row['description'])

  # Attach file
  file_path = Rails.root.join('spec', 'fixtures', 'files', row['fichiers'])
  file = fixture_file_upload(file_path, 'application/pdf')
  response.attach_specialized_document(timestamp, 'fichiers', file)
  response.set_item_field(timestamp, 'fichiers', 'attached')

  response.save!
  @saved_timestamp = timestamp
end

Then('the fichiers should be attached to the échantillon') do
  @market_application.reload
  response = @market_application.market_attribute_responses.last
  fichiers = response.echantillon_fichiers(@saved_timestamp)
  expect(fichiers).to be_present
  expect(fichiers.size).to eq(1)
  expect(fichiers.first.filename.to_s).to eq('test.pdf')
end

Then('I should see the fichiers in the summary') do
  expect(page).to have_content('Fichier')
  expect(page).to have_content('test.pdf')
end

# Multiple files upload test
Given('I have an échantillon with multiple fichiers:') do |table|
  row = table.hashes.first
  response = MarketAttributeResponse::CapacitesTechniquesProfessionnellesOutillageEchantillons.create!(
    market_application: @market_application,
    market_attribute: @echantillons_attr
  )

  timestamp = Time.now.to_i.to_s
  response.set_item_field(timestamp, 'description', row['description'])

  # Attach multiple files
  fichiers = row['fichiers'].split(',')
  fichiers.each do |fichier_name|
    file_path = Rails.root.join('spec', 'fixtures', 'files', fichier_name.strip)
    file = fixture_file_upload(file_path, fichier_name.include?('.pdf') ? 'application/pdf' : 'image/jpeg')
    response.attach_specialized_document(timestamp, 'fichiers', file)
  end
  response.set_item_field(timestamp, 'fichiers', 'attached')

  response.save!
  @saved_timestamp = timestamp
end

Then('all fichiers should be attached to the échantillon') do
  @market_application.reload
  response = @market_application.market_attribute_responses.last
  fichiers = response.echantillon_fichiers(@saved_timestamp)
  expect(fichiers).to be_present
  expect(fichiers.size).to eq(2)
end

Then('I should see all fichiers in the summary') do
  expect(page).to have_content('Fichiers')
  expect(page).to have_content('photo1.jpg')
  expect(page).to have_content('photo2.jpg')
end
