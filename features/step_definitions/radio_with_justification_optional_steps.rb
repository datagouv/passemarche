# frozen_string_literal: true

Given('a public market with radio_with_justification_optional field exists') do
  @editor = create(:editor)
  @public_market = create(:public_market, :completed, editor: @editor)

  @market_attribute_optional = create(
    :market_attribute,
    :radio_with_justification_optional,
    key: 'test_radio_with_justification_optional_field',
    category_key: 'test_capacites_techniques_professionnelles',
    subcategory_key: 'test_capacites_techniques_professionnelles_certificats',
    public_markets: [@public_market],
    required: false
  )
end

Given('a candidate starts an application for this market optional justification') do
  @market_application = create(:market_application, public_market: @public_market, siret: '73282932000074')

  @market_attribute_response_optional = MarketAttributeResponse::RadioWithJustificationOptional.new(
    market_application: @market_application,
    market_attribute: @market_attribute_optional,
    value: {}
  )
  @market_attribute_response_optional.save(validate: false)
end

When('I visit the optional justification field step') do
  visit "/candidate/market_applications/#{@market_application.identifier}/test_capacites_techniques_professionnelles_certificats"
end

When('I select the {string} radio button for optional justification') do |radio_value|
  radio_label = radio_value == 'Yes' ? 'Oui' : 'Non'
  choose radio_label
end

When('I fill in the optional justification text field with {string}') do |text|
  fill_in 'Précisions (optionnel)', with: text
end

When('I attach an optional justification file {string}') do |_filename|
  # Attach to the first visible file input
  all('input[type="file"]', visible: false).first.attach_file(
    Rails.root.join('spec/fixtures/files/document.pdf')
  )
end

Then('the optional justification form should be submitted successfully') do
  expect(page).to have_current_path(
    %r{/candidate/market_applications/#{@market_application.identifier}/.*},
    ignore_query: true
  )
  expect(page).not_to have_content('error')
end

Then('the optional justification radio choice should be {string}') do |choice|
  @market_attribute_response_optional.reload
  expect(@market_attribute_response_optional.radio_choice).to eq(choice)
end

Then('the optional justification response should contain text {string}') do |text|
  @market_attribute_response_optional.reload
  expect(@market_attribute_response_optional.text).to eq(text)
end

Then('the optional justification response should have {int} attached file(s)') do |count|
  @market_attribute_response_optional.reload
  expect(@market_attribute_response_optional.documents.count).to eq(count)
end
