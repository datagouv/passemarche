# frozen_string_literal: true

World(FactoryBot::Syntax::Methods)

# Background steps
Given('a public market with presentation_intervenants field exists') do
  @editor = create(:editor, :authorized_and_active)
  @public_market = create(:public_market, :completed, editor: @editor)

  @cv_intervenants_attr = MarketAttribute.find_or_create_by(key: 'capacites_techniques_professionnelles_effectifs_cv_intervenants') do |attr|
    attr.input_type = 'presentation_intervenants'
    attr.category_key = 'capacites_techniques_professionnelles'
    attr.subcategory_key = 'capacites_techniques_professionnelles_effectifs'
    attr.required = true
  end
  @cv_intervenants_attr.public_markets << @public_market unless @cv_intervenants_attr.public_markets.include?(@public_market)
end

Given('a candidate starts an application for this technical capacities market') do
  @market_application = create(:market_application,
    public_market: @public_market,
    siret: '73282932000074')
end

# Navigation steps
When('I visit the technical capacities step') do
  visit "/candidate/market_applications/#{@market_application.identifier}/capacites_techniques_professionnelles_effectifs"
end

When('I navigate back to the technical capacities step') do
  visit "/candidate/market_applications/#{@market_application.identifier}/capacites_techniques_professionnelles_effectifs"
end

# Display verification steps
Then('I should see the {string} button') do |button_text|
  expect(page).to have_button(button_text)
end

Then('I should see {string} section') do |section_text|
  expect(page).to have_content(section_text)
end

Then('I should see {string} placeholder') do |placeholder_text|
  expect(page).to have_content(placeholder_text)
end

Then('the page should have a nested-form controller for dynamic fields') do
  expect(page).to have_css('[data-controller="nested-form"]')
  expect(page).to have_css('template[data-nested-form-target="template"]', visible: false)
end

Then('the page should have a button to add persons dynamically') do
  expect(page).to have_css('button[data-action="nested-form#add"]')
end

# Person management steps

Then('I should see person form {int} with all required fields') do |person_number|
  expect(page).to have_css("input[name*='person_#{person_number - 1}_nom']")
  expect(page).to have_css("input[name*='person_#{person_number - 1}_prenoms']")
  expect(page).to have_css("textarea[name*='person_#{person_number - 1}_titres']")
  expect(page).to have_css("input[name*='person_#{person_number - 1}_cv_attachment_id']")
end

Then('both person forms should have distinct field names') do
  expect(page).to have_css("input[name*='person_0_nom']")
  expect(page).to have_css("input[name*='person_1_nom']")
end

# Form submission steps (non-JavaScript)

When('I submit the technical capacities form with single person data:') do |table|
  row = table.hashes.first
  timestamp = Time.now.to_i.to_s

  page.driver.submit :patch, "/candidate/market_applications/#{@market_application.identifier}/effectifs",
    market_application: {
      market_attribute_responses_attributes: {
        '0' => {
          id: '',
          market_attribute_id: @cv_intervenants_attr.id.to_s,
          type: 'PresentationIntervenants',
          "person_#{timestamp}_nom" => row['nom'],
          "person_#{timestamp}_prenoms" => row['prenoms'],
          "person_#{timestamp}_titres" => row['titres']
        }
      }
    }
end

When('I submit the technical capacities form with multiple persons data:') do |table|
  base_timestamp = Time.now.to_i
  responses_attrs = {}

  table.hashes.each_with_index do |row, index|
    timestamp = (base_timestamp + index).to_s
    responses_attrs["person_#{timestamp}_nom"] = row['nom']
    responses_attrs["person_#{timestamp}_prenoms"] = row['prenoms']
    responses_attrs["person_#{timestamp}_titres"] = row['titres']
  end

  page.driver.submit :patch, "/candidate/market_applications/#{@market_application.identifier}/effectifs",
    market_application: {
      market_attribute_responses_attributes: {
        '0' => {
          id: '',
          market_attribute_id: @cv_intervenants_attr.id.to_s,
          type: 'CapacitesTechniquesProfessionnellesEffectifsCvIntervenants'
        }.merge(responses_attrs)
      }
    }
end

When('I submit the technical capacities form with person removal:') do |table|
  row = table.hashes.first
  timestamp = Time.now.to_i.to_s

  page.driver.submit :patch, "/candidate/market_applications/#{@market_application.identifier}/effectifs",
    market_application: {
      market_attribute_responses_attributes: {
        '0' => {
          id: '',
          market_attribute_id: @cv_intervenants_attr.id.to_s,
          type: 'PresentationIntervenants',
          "person_#{timestamp}_nom" => row['nom'],
          "person_#{timestamp}_prenoms" => row['prenoms'],
          "person_#{timestamp}_titres" => row['titres']
        }
      }
    }
end

When('I submit the technical capacities form with partial person data:') do |table|
  row = table.hashes.first
  timestamp = Time.now.to_i.to_s

  page.driver.submit :patch, "/candidate/market_applications/#{@market_application.identifier}/effectifs",
    market_application: {
      market_attribute_responses_attributes: {
        '0' => {
          id: '',
          market_attribute_id: @cv_intervenants_attr.id.to_s,
          type: 'PresentationIntervenants',
          "person_#{timestamp}_nom" => row['nom'],
          "person_#{timestamp}_prenoms" => row['prenoms'],
          "person_#{timestamp}_titres" => row['titres']
        }
      }
    }
end

When('I remove person {int}') do |_person_number|
  # Find the delete button within the person's card
  person_card = find("div[data-nested-form-target='item']", match: :first)
  within(person_card) do
    find("button[data-action*='repeatable-item#remove']").click
  end
end

When('I attach a general document {string}') do |filename|
  attach_file('files', Rails.root.join('spec', 'fixtures', 'files', filename), multiple: true)
end

# Form submission steps
Then('the technical capacity form should be submitted successfully') do
  expect(page).not_to have_content('error')
  expect(current_path).not_to include('effectifs')
end

Then('the technical capacity form should not be submitted') do
  expect(current_path).to include('effectifs')
end

# Data verification steps
Then('the person data should be saved correctly') do
  @market_application.reload
  response = @market_application.market_attribute_responses.last
  expect(response).to be_present
  expect(response.class.name).to eq('MarketAttributeResponse::PresentationIntervenants')

  persons = response.persons.values.compact
  expect(persons.length).to eq(1)

  first_person = persons.first
  expect(first_person['nom']).to eq('Dupont')
  expect(first_person['prenoms']).to eq('Jean Pierre')
  expect(first_person['titres']).to eq('Ingénieur informatique, Master')
end

Then('both persons data should be saved correctly') do
  @market_application.reload
  response = @market_application.market_attribute_responses.last
  expect(response).to be_present
  expect(response.persons.length).to eq(2)

  persons = response.persons.values.sort_by { |p| p['nom'] }
  expect(persons[0]['nom']).to eq('Dupont')
  expect(persons[0]['prenoms']).to eq('Jean Pierre')

  expect(persons[1]['nom']).to eq('Martin')
  expect(persons[1]['prenoms']).to eq('Marie Claire')
end

Then('only person {int} data should be saved') do |_person_number|
  @market_application.reload
  response = @market_application.market_attribute_responses.last
  expect(response).to be_present

  # Should only have one person with data
  persons = response.persons.values.compact
  expect(persons.length).to eq(1)

  first_person = persons.first
  expect(first_person['nom']).to eq('Martin')
  expect(first_person['prenoms']).to eq('Marie Claire')
end

Then('the person data with partial information should be saved') do
  @market_application.reload
  response = @market_application.market_attribute_responses.last
  expect(response).to be_present

  persons = response.persons.values.compact
  expect(persons.length).to eq(1)

  first_person = persons.first
  expect(first_person['nom']).to eq('Dupont')
  expect(first_person['prenoms']).to eq('Jean Pierre')
  # titres can be blank
end

Then('the document should be attached to the response') do
  response = @market_application.market_attribute_responses.first
  expect(response.documents).to be_attached
end

# Validation steps (kept for future use)
Then('I should see validation errors for required fields') do
  expect(page).to have_content('error').or have_css('.fr-error-text')
end

# Background data setup for summary tests
Given('I have submitted team data with multiple persons:') do |table|
  response = MarketAttributeResponse::PresentationIntervenants.create!(
    market_application: @market_application,
    market_attribute: @cv_intervenants_attr
  )

  base_timestamp = Time.now.to_i
  table.hashes.each_with_index do |row, index|
    timestamp = (base_timestamp + index).to_s
    response.set_item_field(timestamp, 'nom', row['nom'])
    response.set_item_field(timestamp, 'prenoms', row['prenoms'])
    response.set_item_field(timestamp, 'titres', row['titres'])
  end

  response.save!
end

Given('I have submitted person data:') do |table|
  row = table.hashes.first
  response = MarketAttributeResponse::PresentationIntervenants.create!(
    market_application: @market_application,
    market_attribute: @cv_intervenants_attr
  )

  timestamp = Time.now.to_i.to_s
  response.set_item_field(timestamp, 'nom', row['nom'])
  response.set_item_field(timestamp, 'prenoms', row['prenoms'])
  response.set_item_field(timestamp, 'titres', row['titres'])
  response.save!
  @saved_timestamp = timestamp
end

Given('I have submitted single person data:') do |table|
  row = table.hashes.first
  response = MarketAttributeResponse::PresentationIntervenants.create!(
    market_application: @market_application,
    market_attribute: @cv_intervenants_attr
  )

  timestamp = Time.now.to_i.to_s
  response.set_item_field(timestamp, 'nom', row['nom']) if row['nom'].present?
  response.set_item_field(timestamp, 'prenoms', row['prenoms']) if row['prenoms'].present?
  response.set_item_field(timestamp, 'titres', row['titres']) if row['titres'].present?
  response.save!
end

# Summary display verification
Then('I should see the team data displayed:') do |table|
  table.hashes.each do |row|
    expect(page).to have_content(row['person'])
    expect(page).to have_content(row['nom'])
    expect(page).to have_content(row['prenoms'])
    expect(page).to have_content(row['titres'])
  end
end

# File upload infrastructure steps

Then('I should see file upload infrastructure for documents') do
  expect(page).to have_css('input[type="file"][name*="files"]', visible: false)
  expect(page).to have_content('Téléchargez une liste des intervenants')
end

# Data persistence verification
Then('the saved person data should be displayed in the form') do
  @market_application.reload
  response = @market_application.market_attribute_responses.last
  expect(response).to be_present
  expect(response.persons).not_to be_empty

  # Check that the form displays the saved data
  person_data = response.persons.values.compact.first
  expect(page).to have_field(type: 'text', with: person_data['nom'])
  expect(page).to have_field(type: 'text', with: person_data['prenoms'])
  expect(page).to have_field(type: 'textarea', with: person_data['titres'])
end

# Maximum limit tests
Then('the form should support adding up to 50 persons') do
  # Verify the template exists for dynamic addition (infrastructure test)
  expect(page).to have_css('template[data-nested-form-target="template"]', visible: false)

  # Verify that the model can handle multiple items (tested via set_item_field)
  response = MarketAttributeResponse::PresentationIntervenants.new(
    market_application: @market_application,
    market_attribute: @cv_intervenants_attr
  )

  # Test that we can set fields for 50 different timestamps
  50.times do |i|
    timestamp = (Time.now.to_i + i).to_s
    response.set_item_field(timestamp, 'nom', "Person#{i}")
  end

  expect(response.persons.count).to eq(50)
end

# Empty state tests
When('I click {string} without adding any persons') do |button_text|
  click_button(button_text)
end

Then('I should see {string} in the summary') do |text|
  expect(page).to have_content(text)
end
