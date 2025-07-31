# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
Before do
  supplies_market_type = MarketType.find_or_create_by(code: 'supplies')

  services_market_type = MarketType.find_or_create_by(code: 'services')

  works_market_type = MarketType.find_or_create_by(code: 'works')

  defense_market_type = MarketType.find_or_create_by(code: 'defense')

  siret_attribute = MarketAttribute.find_or_create_by(key: 'siret') do |attr|
    attr.input_type = :text_input
    attr.category_key = 'company_identity'
    attr.subcategory_key = 'basic_information'
    attr.from_api = true
    attr.required = true
  end

  company_name_attribute = MarketAttribute.find_or_create_by(key: 'company_name') do |attr|
    attr.input_type = :text_input
    attr.category_key = 'company_identity'
    attr.subcategory_key = 'basic_information'
    attr.from_api = true
    attr.required = true
  end

  criminal_conviction_attribute = MarketAttribute.find_or_create_by(key: 'criminal_conviction') do |attr|
    attr.input_type = :checkbox
    attr.category_key = 'exclusion_criteria'
    attr.subcategory_key = 'criminal_convictions'
    attr.from_api = false
    attr.required = true
  end

  annual_turnover_attribute = MarketAttribute.find_or_create_by(key: 'annual_turnover') do |attr|
    attr.input_type = :file_upload
    attr.category_key = 'economic_capacity'
    attr.subcategory_key = 'financial_data'
    attr.from_api = false
    attr.required = false
  end

  prior_contract_breach_attribute = MarketAttribute.find_or_create_by(key: 'prior_contract_breach') do |attr|
    attr.input_type = :checkbox
    attr.category_key = 'exclusion_criteria'
    attr.subcategory_key = 'buyer_discretion'
    attr.from_api = false
    attr.required = false
  end

  undue_influence_attribute = MarketAttribute.find_or_create_by(key: 'undue_influence') do |attr|
    attr.input_type = :checkbox
    attr.category_key = 'exclusion_criteria'
    attr.subcategory_key = 'transparency_competition'
    attr.from_api = false
    attr.required = false
  end

  defense_supply_chain_attribute = MarketAttribute.find_or_create_by(key: 'defense_supply_chain') do |attr|
    attr.input_type = :file_upload
    attr.category_key = 'defense_security'
    attr.subcategory_key = 'defense_requirements'
    attr.from_api = false
    attr.required = true
  end

  [siret_attribute, company_name_attribute, criminal_conviction_attribute].each do |attr|
    supplies_market_type.market_attributes << attr unless supplies_market_type.market_attributes.include?(attr)
  end

  [annual_turnover_attribute, prior_contract_breach_attribute, undue_influence_attribute].each do |attr|
    supplies_market_type.market_attributes << attr unless supplies_market_type.market_attributes.include?(attr)
  end

  [defense_supply_chain_attribute].each do |attr|
    defense_market_type.market_attributes << attr unless defense_market_type.market_attributes.include?(attr)
  end

  [siret_attribute, company_name_attribute, criminal_conviction_attribute].each do |attr|
    defense_market_type.market_attributes << attr unless defense_market_type.market_attributes.include?(attr)
  end

  [services_market_type, works_market_type].each do |market_type|
    [siret_attribute, company_name_attribute, criminal_conviction_attribute].each do |attr|
      market_type.market_attributes << attr unless market_type.market_attributes.include?(attr)
    end

    [annual_turnover_attribute, prior_contract_breach_attribute, undue_influence_attribute].each do |attr|
      market_type.market_attributes << attr unless market_type.market_attributes.include?(attr)
    end
  end
end
# rubocop:enable Metrics/BlockLength
