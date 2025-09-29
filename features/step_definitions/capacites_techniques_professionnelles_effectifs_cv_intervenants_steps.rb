# frozen_string_literal: true

World(FactoryBot::Syntax::Methods)

# Background steps
Given('a public market with capacites_techniques_professionnelles_effectifs_cv_intervenants field exists') do
  @editor = create(:editor, :authorized_and_active)
  @public_market = create(:public_market, :completed, editor: @editor)

  @cv_intervenants_attr = MarketAttribute.find_or_create_by(key: 'capacites_techniques_professionnelles_effectifs_cv_intervenants') do |attr|
    attr.input_type = 'capacites_techniques_professionnelles_effectifs_cv_intervenants'
    attr.category_key = 'capacites_techniques_professionnelles'
    attr.subcategory_key = 'effectifs'
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
  visit "/candidate/market_applications/#{@market_application.identifier}/capacites_techniques_professionnelles"
end

When('I navigate back to the technical capacities step') do
  visit "/candidate/market_applications/#{@market_application.identifier}/capacites_techniques_professionnelles"
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

# Form interaction steps
When('I fill in person {int} data:') do |person_number, table|
  person_index = person_number - 1
  row = table.hashes.first

  find("input[name*='person_#{person_index}_nom']").set(row['nom']) if row['nom'].present?

  find("input[name*='person_#{person_index}_prenoms']").set(row['prenoms']) if row['prenoms'].present?

  find("textarea[name*='person_#{person_index}_titres']").set(row['titres']) if row['titres'].present?
end

When('I fill in partial person data:') do |table|
  row = table.hashes.first

  find("input[name*='person_0_nom']").set(row['nom']) if row['nom'].present?

  find("input[name*='person_0_prenoms']").set(row['prenoms']) if row['prenoms'].present?

  find("textarea[name*='person_0_titres']").set(row['titres']) if row['titres'].present?
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
Then('the form should be submitted successfully') do
  expect(page).not_to have_content('error')
  expect(current_path).not_to include('capacites_techniques_professionnelles')
end

Then('the form should not be submitted') do
  expect(current_path).to include('capacites_techniques_professionnelles')
end

# Data verification steps
Then('the person data should be saved correctly') do
  response = @market_application.market_attribute_responses.first
  expect(response).to be_present
  expect(response.type).to eq('MarketAttributeResponse::CapacitesTechniquesProfessionnellesEffectifsCvIntervenants')

  first_person = response.persons.values.first
  expect(first_person['nom']).to eq('Dupont')
  expect(first_person['prenoms']).to eq('Jean Pierre')
  expect(first_person['titres']).to eq('Ingénieur informatique, Master')
end

Then('both persons data should be saved correctly') do
  response = @market_application.market_attribute_responses.first
  expect(response).to be_present
  expect(response.persons.length).to eq(2)

  persons = response.persons_ordered.values
  expect(persons[0]['nom']).to eq('Dupont')
  expect(persons[0]['prenoms']).to eq('Jean Pierre')

  expect(persons[1]['nom']).to eq('Martin')
  expect(persons[1]['prenoms']).to eq('Marie Claire')
end

Then('only person {int} data should be saved') do |_person_number|
  response = @market_application.market_attribute_responses.first
  expect(response).to be_present

  # Should only have one person with data
  filled_persons = response.persons.values.select { |p| p.present? && p.any? { |_k, v| v.present? } }
  expect(filled_persons.length).to eq(1)

  first_person = filled_persons.first
  expect(first_person['nom']).to eq('Martin')
  expect(first_person['prenoms']).to eq('Marie Claire')
end

Then('the document should be attached to the response') do
  response = @market_application.market_attribute_responses.first
  expect(response.documents).to be_attached
end

# Validation steps
Then('I should see validation errors for required fields') do
  expect(page).to have_content('error') | have_css('.fr-error-text')
end

# Background data setup for summary tests
Given('I have submitted team data with multiple persons:') do |table|
  response = MarketAttributeResponse::CapacitesTechniquesProfessionnellesEffectifsCvIntervenants.create!(
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

# Summary display verification
Then('I should see the team data displayed:') do |table|
  table.hashes.each do |row|
    expect(page).to have_content(row['person'])
    expect(page).to have_content(row['nom'])
    expect(page).to have_content(row['prenoms'])
    expect(page).to have_content(row['titres'])
  end
end

# STI verification steps

When('I submit valid team data') do
  click_button('Ajouter une personne')
  find("input[name*='person_0_nom']").set('Test')
  find("input[name*='person_0_prenoms']").set('User')
  find("textarea[name*='person_0_titres']").set('Test Engineer')
  click_button('Suivant')
end

Then('the response should be created with class {string}') do |class_name|
  response = @market_application.market_attribute_responses.first
  expect(response.class.name).to eq(class_name)
end

Then('the response should have the correct JSON structure') do
  response = @market_application.market_attribute_responses.first
  expect(response.value).to be_a(Hash)
  expect(response.value).to have_key('items')
  expect(response.value['items']).to be_a(Hash)
end

# Data persistence verification
Then('the person {int} fields should contain the saved data:') do |person_number, table|
  person_index = person_number - 1
  row = table.hashes.first

  expect(find("input[name*='person_#{person_index}_nom']").value).to eq(row['nom'])
  expect(find("input[name*='person_#{person_index}_prenoms']").value).to eq(row['prenoms'])
  expect(find("textarea[name*='person_#{person_index}_titres']").value).to eq(row['titres'])
end

# Maximum limit tests
When('I add {int} persons') do |count|
  count.times do |i|
    click_button('Ajouter une personne')
    find("input[name*='person_#{i}_nom']").set("Person#{i + 1}")
    find("input[name*='person_#{i}_prenoms']").set('Test')
  end
end

Then('the {string} button should be disabled') do |button_text|
  expect(page).to have_button(button_text, disabled: true)
end

When('I try to add another person') do
  # Try to click the button even if disabled
  page.execute_script("document.querySelector('button:contains(\"Ajouter une personne\")').click()")
end

Then('no additional person form should appear') do
  expect(page).to have_css("input[name*='person_'][name*='_nom']", count: 50)
end

# Empty state tests
When('I click {string} without adding any persons') do |button_text|
  click_button(button_text)
end

Then('I should see {string} in the summary') do |text|
  expect(page).to have_content(text)
end
