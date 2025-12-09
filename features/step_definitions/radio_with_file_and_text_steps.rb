# frozen_string_literal: true

Given('a public market with radio_with_file_and_text field exists') do
  @editor = create(:editor)
  @public_market = create(:public_market, :completed, editor: @editor)

  @market_attribute = create(
    :market_attribute,
    :radio_with_file_and_text,
    key: 'test_radio_with_file_and_text_field',
    category_key: 'test_capacites_techniques_professionnelles',
    subcategory_key: 'test_capacites_techniques_professionnelles_certificats',
    public_markets: [@public_market],
    mandatory: false
  )
end

Given('a candidate starts an application for this market radio') do
  @market_application = create(:market_application, public_market: @public_market, siret: '73282932000074')

  @market_attribute_response = MarketAttributeResponse::RadioWithFileAndText.create!(
    market_application: @market_application,
    market_attribute: @market_attribute,
    value: {}
  )
end

When('I visit the radio field step') do
  visit "/candidate/market_applications/#{@market_application.identifier}/test_capacites_techniques_professionnelles_certificats"
end

Then('the {string} radio button should be checked') do |radio_value|
  radio_id = if radio_value == 'Yes'
               'market_application_market_attribute_responses_attributes_0_radio_choice_yes'
             else
               'market_application_market_attribute_responses_attributes_0_radio_choice_no'
             end

  expect(page).to have_checked_field(radio_id)
end

Then('the conditional fields should be hidden') do
  expect(page).to have_css('[data-conditional-fields-target="content"].fr-hidden')
end

When('I select the {string} radio button') do |radio_value|
  radio_label = radio_value == 'Yes' ? 'Oui' : 'Non'
  choose radio_label
end

Then('the conditional text field should be visible') do
  expect(page).to have_css('[data-conditional-fields-target="content"]:not(.fr-hidden)')
  expect(page).to have_field('Décrivez votre situation')
end

Then('the conditional file upload should be visible') do
  expect(page).to have_css('[data-conditional-fields-target="content"]:not(.fr-hidden)')
  expect(page).to have_content('Ajouter vos documents')
end

When('I fill in the text field with {string}') do |text|
  within('[data-conditional-fields-target="content"]') do
    fill_in 'Décrivez votre situation', with: text
  end
end

When('I attach a file {string}') do |filename|
  within('[data-conditional-fields-target="content"]') do
    attach_file(
      'Ajouter vos documents',
      Rails.root.join('spec', 'fixtures', 'files', filename),
      make_visible: true
    )
  end
end

Then('the radio form should be submitted successfully') do
  expect(page).to have_current_path(
    %r{/candidate/market_applications/#{@market_application.identifier}/.*},
    ignore_query: true
  )
  expect(page).not_to have_content('error')
end

Then('the radio choice should be {string}') do |choice|
  response = @market_application.market_attribute_responses.reload.find_by(market_attribute: @market_attribute)
  expect(response).to be_present
  expect(response.radio_choice).to eq(choice)
end

Then('the radio response should contain text {string}') do |text|
  response = @market_application.market_attribute_responses.reload.find_by(market_attribute: @market_attribute)
  expect(response).to be_present
  expect(response.text).to eq(text)
end

Then('the radio response should have {int} attached file(s)') do |count|
  response = @market_application.market_attribute_responses.reload.find_by(market_attribute: @market_attribute)
  expect(response).to be_present
  expect(response.documents.count).to eq(count)
end
