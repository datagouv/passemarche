# frozen_string_literal: true

Then('each form field should have a type hidden field with correct STI class') do
  hidden_types = page.all('input[name*="[type]"][type="hidden"]', visible: false)
  expect(hidden_types).not_to be_empty
  hidden_types.each do |field|
    expect(%w[TextInput EmailInput PhoneInput]).to include(field.value)
  end
end

Then('each checkbox field should have type {string}') do |expected_type|
  expect(page.all('input[name*="[type]"][type="hidden"]', visible: false).map(&:value)).to include(expected_type)
end

Then('each textarea field should have type {string}') do |expected_type|
  expect(page.all('input[name*="[type]"][type="hidden"]', visible: false).map(&:value)).to include(expected_type)
end

Then('each file upload field should have type {string}') do |expected_type|
  expect(page.all('input[name*="[type]"][type="hidden"]', visible: false).map(&:value)).to include(expected_type)
end

Then('all responses should be created with correct STI types') do
  @market_application.reload
  responses = @market_application.market_attribute_responses
  expect(responses).not_to be_empty
  responses.each do |response|
    expect(response.type).to be_present
    expect(response.class.name).to start_with('MarketAttributeResponse::')
  end
end

Then('the email response should be of class {string}') do |expected_class|
  response = @market_application.market_attribute_responses.find { |r| r.market_attribute.input_type == 'email_input' }
  expect(response).to be_present
  expect(response.class.name).to eq(expected_class)
end

Then('the phone response should be of class {string}') do |expected_class|
  response = @market_application.market_attribute_responses.find { |r| r.market_attribute.input_type == 'phone_input' }
  expect(response).to be_present
  expect(response.class.name).to eq(expected_class)
end

Then('the text response should be of class {string}') do |expected_class|
  response = @market_application.market_attribute_responses.find { |r| r.market_attribute.input_type == 'text_input' }
  expect(response).to be_present
  expect(response.class.name).to eq(expected_class)
end

Then('the checkbox response should be of class {string}') do |expected_class|
  response = @market_application.market_attribute_responses.find { |r| r.market_attribute.input_type == 'checkbox_with_document' }
  expect(response).to be_present
  expect(response.class.name).to eq(expected_class)
end

Then('the textarea response should be of class {string}') do |expected_class|
  response = @market_application.market_attribute_responses.find { |r| r.market_attribute.input_type == 'textarea' }
  expect(response).to be_present
  expect(response.class.name).to eq(expected_class)
end

Then('the file upload response should be of class {string}') do |expected_class|
  response = @market_application.market_attribute_responses.find { |r| r.market_attribute.input_type == 'file_upload' }
  expect(response).to be_present
  expect(response.class.name).to eq(expected_class)
end

Then('the response should be of type {string}') do |expected_type|
  @market_application.reload
  response = @market_application.market_attribute_responses.find { |r| r.market_attribute.input_type == 'checkbox_with_document' }
  expect(response).to be_present
  expect(response.type).to eq(expected_type)
end

Then('it should have both checked status and attached file') do
  response = @market_application.market_attribute_responses.find { |r| r.market_attribute.input_type == 'checkbox_with_document' }
  expect(response.checked).to be_truthy
  expect(response.documents).to be_attached
end
