# frozen_string_literal: true

Given('a public market with radio_with_justification_required field exists') do
  @editor = create(:editor)
  @public_market = create(:public_market, :completed, editor: @editor)

  @market_attribute = create(
    :market_attribute,
    :radio_with_justification_required,
    key: 'test_radio_with_justification_required_field',
    category_key: 'test_capacites_techniques_professionnelles',
    subcategory_key: 'test_capacites_techniques_professionnelles_certificats',
    public_markets: [@public_market],
    required: false
  )
end

Given('a candidate starts an application for this market justification') do
  @market_application = create(:market_application, public_market: @public_market, siret: '73282932000074')

  @market_attribute_response = MarketAttributeResponse::RadioWithJustificationRequired.new(
    market_application: @market_application,
    market_attribute: @market_attribute,
    value: {}
  )
  @market_attribute_response.save(validate: false)
end

When('I visit the justification field step') do
  visit "/candidate/market_applications/#{@market_application.identifier}/test_capacites_techniques_professionnelles_certificats"
end

When('I select the {string} radio button for justification') do |radio_value|
  radio_label = radio_value == 'Yes' ? 'Oui' : 'Non'
  choose radio_label
end

When('I fill in the justification text field with {string}') do |text|
  fill_in 'Précisions (optionnel)', with: text
end

When('I attach a justification file {string}') do |_filename|
  # Attach to the first visible file input
  all('input[type="file"]', visible: false).first.attach_file(
    Rails.root.join('spec/fixtures/files/document.pdf')
  )
end

Then('the justification form should be submitted successfully') do
  expect(page).to have_current_path(
    %r{/candidate/market_applications/#{@market_application.identifier}/.*},
    ignore_query: true
  )
  expect(page).not_to have_content('error')
end

Then('the justification form should fail validation') do
  expect(page).to have_current_path(
    %r{/candidate/market_applications/#{@market_application.identifier}/test_capacites_techniques_professionnelles_certificats},
    ignore_query: true
  )
end

Then('I should see a document required error') do
  expect(page).to have_content('Documents est requis')
end

Then('the justification radio choice should be {string}') do |choice|
  @market_attribute_response.reload
  expect(@market_attribute_response.radio_choice).to eq(choice)
end

Then('the justification response should contain text {string}') do |text|
  @market_attribute_response.reload
  expect(@market_attribute_response.text).to eq(text)
end

Then('the justification response should have {int} attached file(s)') do |count|
  @market_attribute_response.reload
  expect(@market_attribute_response.documents.count).to eq(count)
end
