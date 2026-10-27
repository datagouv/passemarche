# frozen_string_literal: true

Given('this application leads a grouping as mandataire {string}') do |email|
  @market_application.update!(application_mode: :groupement, user: create(:user, email:))
  create(:grouping, public_market: @public_market, mandataire_market_application: @market_application)
end

Given('I am authenticated as a co-traitant of this grouping') do
  @co_traitant_application = create(:market_application, public_market: @public_market,
    application_mode: :groupement, siret: VALID_TEST_SIRETS[0])
  create(:grouping_member, :co_traitant, grouping: mandataire_grouping, siret: VALID_TEST_SIRETS[0],
    market_application: @co_traitant_application, **invitation_sent_attributes)
  authenticate_as_candidate_for(@co_traitant_application)
end

When('I visit my co-traitant form step {string}') do |step|
  visit step_candidate_market_application_path(@co_traitant_application.identifier, step)
end

Then('{string} should receive the email {string}') do |email, subject|
  expect(ActionMailer::Base.deliveries.map { |mail| [mail.to, mail.subject] }).to include([[email], subject])
end

Given('the market asks for a text field {string} in the {string} step') do |key, step|
  @draft_attributes ||= {}
  @draft_attributes[key] = create(:market_attribute, :text_input, key:, category_key: step, subcategory_key: step,
    public_markets: [@public_market])
end

Given('the market has a works lot and a services lot') do
  @public_market.update!(market_type_codes: %w[works services])
  @works_lot = create(:lot, public_market: @public_market, market_type: MarketType.find_or_create_by!(code: 'works'))
  @services_lot = create(:lot, public_market: @public_market,
    market_type: MarketType.find_or_create_by!(code: 'services'))
end

Given('the market asks for a {word} text field {string} in the {string} step') do |type_code, key, step|
  @draft_attributes ||= {}
  @draft_attributes[key] = create(:market_attribute, :text_input, key:, category_key: step, subcategory_key: step,
    public_markets: [@public_market], market_types: [MarketType.find_by!(code: type_code)])
end

Given('I declared only the services lot') do
  @co_traitant_application.lots = [@services_lot]
end

Then('I should see the {string} field') do |key|
  expect(page).to have_css(market_attribute_id_field_selector(key), visible: false)
end

Then('I should not see the {string} field') do |key|
  expect(page).to have_no_css(market_attribute_id_field_selector(key), visible: false)
end

When('I fill in the {string} field with {string}') do |key, value|
  find(draft_text_field_selector(key)).set(value)
end

Then('the {string} field should contain {string}') do |key, value|
  expect(find(draft_text_field_selector(key)).value).to eq(value)
end

def draft_text_field_selector(key)
  hidden_field = find(market_attribute_id_field_selector(key), visible: false)
  "input[name='#{hidden_field[:name].sub('[market_attribute_id]', '[text]')}']"
end

def market_attribute_id_field_selector(key)
  "input[type=hidden][name$='[market_attribute_id]'][value='#{@draft_attributes.fetch(key).id}']"
end
