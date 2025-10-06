# frozen_string_literal: true

World(FactoryBot::Syntax::Methods)

# Background steps
Given('a public market with capacites_techniques_professionnelles_realisations_livraisons_cinq_ans field exists') do
  @editor = create(:editor, :authorized_and_active)
  @public_market = create(:public_market, :completed, editor: @editor)

  @realisations_attr = MarketAttribute.find_or_create_by(
    key: 'capacites_techniques_professionnelles_realisations_livraisons_cinq_ans'
  ) do |attr|
    attr.input_type = 'capacites_techniques_professionnelles_realisations_livraisons_cinq_ans'
    attr.category_key = 'capacites_techniques_professionnelles'
    attr.subcategory_key = 'capacites_techniques_professionnelles_realisations'
    attr.required = true
  end
  @realisations_attr.public_markets << @public_market unless @realisations_attr.public_markets.include?(@public_market)
end

Given('a candidate starts an application for this realisations market') do
  @market_application = create(:market_application,
    public_market: @public_market,
    siret: '73282932000074')
end

# Navigation steps
When('I visit the realisations step') do
  visit "/candidate/market_applications/#{@market_application.identifier}/capacites_techniques_professionnelles_realisations"
end

When('I navigate back to the realisations step') do
  visit "/candidate/market_applications/#{@market_application.identifier}/capacites_techniques_professionnelles_realisations"
end

# Display verification steps
Then('I should see the realisations {string} button') do |button_text|
  expect(page).to have_button(button_text)
end

Then('the realisations page should have a nested-form controller for dynamic fields') do
  expect(page).to have_css('[data-controller="nested-form"]')
  expect(page).to have_css('template[data-nested-form-target="template"]', visible: false)
end

Then('the realisations page should have a button to add realisations dynamically') do
  expect(page).to have_css('button[data-action="nested-form#add"]')
end

# Form submission steps (non-JavaScript)
Given('I have submitted single realisation data:') do |table|
  row = table.hashes.first
  timestamp = Time.now.to_i.to_s

  page.driver.submit :patch, "/candidate/market_applications/#{@market_application.identifier}/capacites_techniques_professionnelles_realisations",
    market_application: {
      market_attribute_responses_attributes: {
        '0' => {
          id: '',
          market_attribute_id: @realisations_attr.id.to_s,
          type: 'CapacitesTechniquesProfessionnellesRealisationsLivraisonsCinqAns',
          "realisation_#{timestamp}_resume" => row['resume'],
          "realisation_#{timestamp}_date_debut" => row['date_debut'],
          "realisation_#{timestamp}_date_fin" => row['date_fin'],
          "realisation_#{timestamp}_montant" => row['montant'],
          "realisation_#{timestamp}_description" => row['description']
        }
      }
    }
end

Given('I have submitted realisations data with multiple items:') do |table|
  base_timestamp = Time.now.to_i
  responses_attrs = {}

  table.hashes.each_with_index do |row, index|
    timestamp = (base_timestamp + index).to_s
    responses_attrs["realisation_#{timestamp}_resume"] = row['resume']
    responses_attrs["realisation_#{timestamp}_date_debut"] = row['date_debut']
    responses_attrs["realisation_#{timestamp}_date_fin"] = row['date_fin']
    responses_attrs["realisation_#{timestamp}_montant"] = row['montant']
    responses_attrs["realisation_#{timestamp}_description"] = row['description']
  end

  page.driver.submit :patch, "/candidate/market_applications/#{@market_application.identifier}/capacites_techniques_professionnelles_realisations",
    market_application: {
      market_attribute_responses_attributes: {
        '0' => {
          id: '',
          market_attribute_id: @realisations_attr.id.to_s,
          type: 'CapacitesTechniquesProfessionnellesRealisationsLivraisonsCinqAns'
        }.merge(responses_attrs)
      }
    }
end

When('I submit invalid date range realisation:') do |table|
  row = table.hashes.first
  timestamp = Time.now.to_i.to_s

  page.driver.submit :patch, "/candidate/market_applications/#{@market_application.identifier}/capacites_techniques_professionnelles_realisations",
    market_application: {
      market_attribute_responses_attributes: {
        '0' => {
          id: '',
          market_attribute_id: @realisations_attr.id.to_s,
          type: 'CapacitesTechniquesProfessionnellesRealisationsLivraisonsCinqAns',
          "realisation_#{timestamp}_resume" => row['resume'],
          "realisation_#{timestamp}_date_debut" => row['date_debut'],
          "realisation_#{timestamp}_date_fin" => row['date_fin'],
          "realisation_#{timestamp}_montant" => row['montant'],
          "realisation_#{timestamp}_description" => row['description']
        }
      }
    }
end

When('I submit invalid montant realisation:') do |table|
  row = table.hashes.first
  timestamp = Time.now.to_i.to_s

  page.driver.submit :patch, "/candidate/market_applications/#{@market_application.identifier}/capacites_techniques_professionnelles_realisations",
    market_application: {
      market_attribute_responses_attributes: {
        '0' => {
          id: '',
          market_attribute_id: @realisations_attr.id.to_s,
          type: 'CapacitesTechniquesProfessionnellesRealisationsLivraisonsCinqAns',
          "realisation_#{timestamp}_resume" => row['resume'],
          "realisation_#{timestamp}_date_debut" => row['date_debut'],
          "realisation_#{timestamp}_date_fin" => row['date_fin'],
          "realisation_#{timestamp}_montant" => row['montant'],
          "realisation_#{timestamp}_description" => row['description']
        }
      }
    }
end

Then('I should see validation error {string}') do |error_text|
  expect(page).to have_content(error_text)
end

# Data verification steps
Then('the realisation data should be saved correctly') do
  @market_application.reload
  response = @market_application.market_attribute_responses.last
  expect(response).to be_present
  expect(response.class.name).to eq('MarketAttributeResponse::CapacitesTechniquesProfessionnellesRealisationsLivraisonsCinqAns')

  realisations = response.realisations.values.compact
  expect(realisations.length).to eq(1)

  first_realisation = realisations.first
  expect(first_realisation['resume']).to eq('Construction bâtiment municipal')
  expect(first_realisation['montant']).to eq(500_000)
  expect(first_realisation['description']).to eq('Construction complète incluant gros œuvre et finitions')
end

Then('both realisations data should be saved correctly') do
  @market_application.reload
  response = @market_application.market_attribute_responses.last
  expect(response).to be_present
  expect(response.realisations.length).to eq(2)

  realisations = response.realisations.values.sort_by { |r| r['resume'] }
  expect(realisations[0]['resume']).to eq('Construction bâtiment municipal')
  expect(realisations[1]['resume']).to eq('Rénovation école primaire')
end

Then('only realisation {int} data should be saved') do |_realisation_number|
  @market_application.reload
  response = @market_application.market_attribute_responses.last
  expect(response).to be_present

  realisations = response.realisations.values.compact
  expect(realisations.length).to eq(1)

  first_realisation = realisations.first
  expect(first_realisation['resume']).to eq('Rénovation école')
end

# Background data setup for summary tests
Given('I have submitted realisation data:') do |table|
  row = table.hashes.first
  response = MarketAttributeResponse::CapacitesTechniquesProfessionnellesRealisationsLivraisonsCinqAns.create!(
    market_application: @market_application,
    market_attribute: @realisations_attr
  )

  timestamp = Time.now.to_i.to_s
  response.set_item_field(timestamp, 'resume', row['resume'])
  response.set_item_field(timestamp, 'date_debut', row['date_debut'])
  response.set_item_field(timestamp, 'date_fin', row['date_fin'])
  response.set_item_field(timestamp, 'montant', row['montant'])
  response.set_item_field(timestamp, 'description', row['description'])
  response.save!
  @saved_timestamp = timestamp
end

# Summary display verification
Then('I should see the realisations data displayed:') do |table|
  table.hashes.each do |row|
    expect(page).to have_content(row['realisation'])
    expect(page).to have_content(row['resume'])
    expect(page).to have_content(row['montant'])
  end
end

# Data persistence verification
Then('the saved realisation data should be displayed in the form') do
  @market_application.reload
  response = @market_application.market_attribute_responses.last
  expect(response).to be_present
  expect(response.realisations).not_to be_empty

  realisation_data = response.realisations.values.compact.first
  expect(page).to have_field(type: 'text', with: realisation_data['resume'])
  expect(page).to have_field(type: 'date', with: realisation_data['date_debut'])
  expect(page).to have_field(type: 'number', with: realisation_data['montant'].to_s)
end

# Empty state tests
When('I click {string} without adding any realisations') do |button_text|
  click_button(button_text)
end

Then('I should see {string} in the realisations summary') do |text|
  expect(page).to have_content(text)
end

# File upload tests
Given('I have a realisation with attestation:') do |table|
  row = table.hashes.first
  response = MarketAttributeResponse::CapacitesTechniquesProfessionnellesRealisationsLivraisonsCinqAns.create!(
    market_application: @market_application,
    market_attribute: @realisations_attr
  )

  timestamp = Time.now.to_i.to_s
  response.set_item_field(timestamp, 'resume', row['resume'])
  response.set_item_field(timestamp, 'date_debut', row['date_debut'])
  response.set_item_field(timestamp, 'date_fin', row['date_fin'])
  response.set_item_field(timestamp, 'montant', row['montant'])
  response.set_item_field(timestamp, 'description', row['description'])

  # Attach file
  file_path = Rails.root.join('spec', 'fixtures', 'files', row['attestation'])
  file = fixture_file_upload(file_path, 'application/pdf')
  response.attach_specialized_document(timestamp, 'attestation_bonne_execution', file)
  response.set_item_field(timestamp, 'attestation_bonne_execution', 'attached')

  response.save!
  @saved_timestamp = timestamp
end

Then('the attestation should be attached to the realisation') do
  @market_application.reload
  response = @market_application.market_attribute_responses.last
  attestations = response.realisation_attestations(@saved_timestamp)
  expect(attestations).to be_present
  expect(attestations.size).to eq(1)
  expect(attestations.first.filename.to_s).to eq('test.pdf')
end

Then('I should see the attestation in the summary') do
  expect(page).to have_content('Attestation')
  expect(page).to have_link('test.pdf')
end
