# frozen_string_literal: true

require 'webmock/cucumber'

World(FactoryBot::Syntax::Methods)

Given('an editor {string} exists') do |editor_name|
  @editor = Editor.find_or_create_by(name: editor_name) do |editor|
    editor.client_id = 'test_client_id'
    editor.client_secret = 'test_client_secret'
    editor.authorized = true
    editor.active = true
  end
end

Given('a public market with soft-deletable attributes exists') do
  @public_market = create(:public_market, :completed, editor: @editor)

  @active_field_1 = MarketAttribute.find_or_create_by(key: 'active_field_1') do |attr|
    attr.input_type = 'text_input'
    attr.category_key = 'identite_entreprise'
    attr.subcategory_key = 'contact'
    attr.required = true
    attr.deleted_at = nil
  end
  @active_field_1.public_markets << @public_market unless @active_field_1.public_markets.include?(@public_market)

  @to_be_deleted_field = MarketAttribute.find_or_create_by(key: 'to_be_deleted_field') do |attr|
    attr.input_type = 'text_input'
    attr.category_key = 'identite_entreprise'
    attr.subcategory_key = 'contact'
    attr.required = true
    attr.deleted_at = nil
  end
  @to_be_deleted_field.public_markets << @public_market unless @to_be_deleted_field.public_markets.include?(@public_market)

  @active_field_2 = MarketAttribute.find_or_create_by(key: 'active_field_2') do |attr|
    attr.input_type = 'textarea'
    attr.category_key = 'identite_entreprise'
    attr.subcategory_key = 'contact'
    attr.required = false
    attr.deleted_at = nil
  end
  @active_field_2.public_markets << @public_market unless @active_field_2.public_markets.include?(@public_market)
end

Given('a candidate starts an application for the market') do
  @market_application = create(:market_application,
    public_market: @public_market,
    siret: nil)

  stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v3/insee/sirene/etablissements/73282932000074.*})
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
end

Then('I should see a field with key {string}') do |field_key|
  attribute = MarketAttribute.find_by(key: field_key)
  expect(page).to have_css("[name*='[#{attribute.id}]']", visible: :all)
end

When('the market attribute {string} is soft-deleted') do |key|
  attribute = MarketAttribute.find_by!(key:)
  attribute.update!(deleted_at: Time.current)
end

When('I reload the page') do
  visit current_path
end

When('I fill in the field with key {string} with {string}') do |field_key, value|
  attribute = MarketAttribute.find_by(key: field_key)
  field_name = "market_application[market_attribute_responses_attributes][][#{attribute.id}][value]"

  raise "Unsupported input type: #{attribute.input_type}" unless %w[text_input textarea].include?(attribute.input_type)

  fill_in field_name, with: value
end

Then('I should not see validation errors') do
  expect(page).not_to have_css('.error')
  expect(page).not_to have_content('ne peut pas être vide')
end
