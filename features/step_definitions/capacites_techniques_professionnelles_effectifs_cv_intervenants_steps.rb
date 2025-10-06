# frozen_string_literal: true

World(FactoryBot::Syntax::Methods)

# Background steps - specific to capacites_techniques_professionnelles_effectifs_cv_intervenants
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

# Data verification steps - specific to capacites_techniques_professionnelles_effectifs_cv_intervenants
Then('the person data should be saved correctly \(effectifs cv intervenants\)') do
  @market_application.reload
  response = @market_application.market_attribute_responses.last
  expect(response).to be_present
  expect(response.class.name).to eq('MarketAttributeResponse::CapacitesTechniquesProfessionnellesEffectifsCvIntervenants')

  persons = response.persons.values.compact
  expect(persons.length).to eq(1)

  first_person = persons.first
  expect(first_person['nom']).to eq('Dupont')
  expect(first_person['prenoms']).to eq('Jean Pierre')
  expect(first_person['titres']).to eq('Ingénieur informatique, Master')
end

# Background data setup for summary tests - specific to capacites_techniques_professionnelles_effectifs_cv_intervenants
Given('I have submitted team data with multiple persons \(effectifs cv intervenants\):') do |table|
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

Given('I have submitted single person data \(effectifs cv intervenants\):') do |table|
  row = table.hashes.first
  response = MarketAttributeResponse::CapacitesTechniquesProfessionnellesEffectifsCvIntervenants.create!(
    market_application: @market_application,
    market_attribute: @cv_intervenants_attr
  )

  timestamp = Time.now.to_i.to_s
  response.set_item_field(timestamp, 'nom', row['nom']) if row['nom'].present?
  response.set_item_field(timestamp, 'prenoms', row['prenoms']) if row['prenoms'].present?
  response.set_item_field(timestamp, 'titres', row['titres']) if row['titres'].present?
  response.save!
end
