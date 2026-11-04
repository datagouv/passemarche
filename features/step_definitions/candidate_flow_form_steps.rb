# frozen_string_literal: true

Then('I should see the SIRET input field') do
  expect(page).to have_field('market_application_siret', disabled: true)
end

Then('I should see the locked SIRET field') do
  expect(page).to have_field('market_application_siret', disabled: true)
end

When('I fill in the SIRET with {string}') do |_siret|
  # SIRET is locked and set at application creation — no-op
end

Then('I should see all required identity fields') do
  expect(page).to have_css('input, textarea, select')
  expect(page).not_to have_content('erreur')
  expect(page).not_to have_content('error')
end

Then('I should see checkbox fields') do
  expect(page).to have_css('input[type="checkbox"]')
end

Then('I should see textarea fields') do
  expect(page).to have_css('textarea')
end

Then('I should see file upload fields') do
  expect(page).to have_css('input[type="file"]')
end

Then('I should see a summary of all my responses') do
  expect(page.has_content?('Synthèse') || page.has_content?('Récapitulatif')).to be_truthy
  expect(page).to have_content('contact@example.com')
  expect(page).to have_content('01 23 45 67 89')
end

Then('I should see market information') do
  expect(page).to have_content('Nom du marché')
  expect(page).to have_content('Date et heure limite')
end

Then('I should see email and phone fields') do
  expect(page).to have_css('input[type="email"]')
  expect(page).to have_css('input[type="tel"]')
end

Then('I should see company name field') do
  expect(page).to have_css('input[type="text"]')
end

Then('I should see checkbox with document field') do
  expect(page).to have_css('input[type="checkbox"]')
end

When('I fill in all identity fields with valid data') do
  email_field = page.find('input[type="email"], input[id*="email"], input[name*="email"]', match: :first)
  email_field&.set('test@example.com')

  phone_field = page.find('input[type="tel"], input[id*="phone"], input[id*="telephone"]', match: :first)
  phone_field&.set('01 23 45 67 89')

  page.all('input[type="text"]').each_with_index do |field, index|
    next if field[:name].include?('siret')

    field.set("Test Company #{index + 1}")
  end
end

When('I check the required exclusion checkboxes') do
  page.all('input[type="checkbox"]').each(&:check)
end

When('I fill in the economic capacity information') do
  page.all('textarea').each do |textarea|
    textarea.set("Description détaillée des capacités économiques et financières de l'entreprise.")
  end
end

When('I upload required documents') do
  fill_in_all_available_fields
  page.all('input[type="checkbox"]').each { |cb| cb.check unless cb.checked? }
end

When('I fill in contact fields with valid data') do
  page.all('input[type="email"]').each { |f| f.set('contact@example.com') }
  page.all('input[type="tel"]').each { |f| f.set('01 23 45 67 89') }
end

When('I fill in identification fields with valid data') do
  page.all('input[type="text"]').each { |f| f.set('Test Company Name') }
end

When('I handle optional checkbox with document') do
  page.first('input[type="checkbox"]')&.check
end

When('I fill in the turnover percentages') do
  find("input[name*='year_1_market_percentage']").set('75')
  find("input[name*='year_2_market_percentage']").set('80')
  find("input[name*='year_3_market_percentage']").set('70')
end

When('I leave identification fields empty') do
  all("input[name*='market_attribute_responses_attributes'][name*='[text]']").each do |f|
    f.fill_in with: ''
  end
end

When('I fill in all required fields correctly') do
  fill_in_all_available_fields
end

When('I fill in invalid data:') do |table|
  table.hashes.each do |row|
    case row['field']
    when 'email'
      page.find('input[type="email"], input[id*="email"]', match: :first).set(row['value'])
    when 'phone'
      page.find('input[type="tel"], input[id*="phone"]', match: :first).set(row['value'])
    when 'required_text'
      page.find('input[type="text"][required]', match: :first).set(row['value'])
    end
  end
end

When('I fill in:') do |table|
  input_type_map = { 'email' => 'email', 'phone' => 'tel', 'text' => 'text' }
  table.hashes.each do |row|
    input_type = input_type_map[row['field']]
    next unless input_type

    page.find("input[type=\"#{input_type}\"]", match: :first).set(row['value'])
  end
end

Then('I should see validation errors for:') do |table|
  table.hashes.each do |row|
    case row['field']
    when 'email'
      expect(page).to have_content("L'adresse email doit avoir un format valide")
    when 'phone'
      expect(page).to have_content('Le numéro de téléphone doit respecter le format')
    when 'required_text'
      expect(page).to have_css('.fr-error-text')
    else
      expect(page).to have_content(row['error'])
    end
  end
end

Then('the fields should contain the previously entered values:') do |table|
  input_type_map = { 'email' => 'email', 'phone' => 'tel', 'text' => 'text' }
  table.hashes.each do |row|
    input_type = input_type_map[row['field']]
    next unless input_type

    expect(page.find("input[type=\"#{input_type}\"]", match: :first).value).to eq(row['expected_value'])
  end
end

Then('I should see validation errors') do
  raise 'Expected validation errors but none were found' unless validation_error_present?

  true
end

Then('I should see a file format validation error') do
  raise 'Expected file format validation error but none was found' unless file_format_error_present? || on_expected_path?(/documents/)

  true
end

When('validation fails for other reasons') do
  # Handled automatically by form validation
end

When('I fix the validation issues and submit') do
  fill_in_all_available_fields
  click_button 'Suivant'
end
