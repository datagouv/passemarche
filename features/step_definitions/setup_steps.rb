# frozen_string_literal: true

Before do
  setup_market_types_and_attributes
end

def setup_market_types_and_attributes
  market_types = create_market_types
  attributes = create_market_attributes
  associate_attributes_with_market_types(market_types, attributes)
end

def create_market_types
  {
    supplies: MarketType.find_or_create_by(code: 'supplies'),
    services: MarketType.find_or_create_by(code: 'services'),
    works: MarketType.find_or_create_by(code: 'works'),
    defense: MarketType.find_or_create_by(code: 'defense')
  }
end

def create_market_attributes
  {
    siret: create_siret_attribute,
    company_name: create_company_name_attribute,
    criminal_conviction: create_criminal_conviction_attribute,
    annual_turnover: create_annual_turnover_attribute,
    prior_contract_breach: create_prior_contract_breach_attribute,
    undue_influence: create_undue_influence_attribute,
    defense_supply_chain: create_defense_supply_chain_attribute
  }
end

def create_siret_attribute
  MarketAttribute.find_or_create_by(key: 'siret') do |attr|
    attr.input_type = :text_input
    attr.category_key = 'company_identity'
    attr.subcategory_key = 'basic_information'
    attr.from_api = true
    attr.required = true
  end
end

def create_company_name_attribute
  MarketAttribute.find_or_create_by(key: 'company_name') do |attr|
    attr.input_type = :text_input
    attr.category_key = 'company_identity'
    attr.subcategory_key = 'basic_information'
    attr.from_api = true
    attr.required = true
  end
end

def create_criminal_conviction_attribute
  MarketAttribute.find_or_create_by(key: 'criminal_conviction') do |attr|
    attr.input_type = :checkbox
    attr.category_key = 'exclusion_criteria'
    attr.subcategory_key = 'criminal_convictions'
    attr.from_api = false
    attr.required = true
  end
end

def create_annual_turnover_attribute
  MarketAttribute.find_or_create_by(key: 'annual_turnover') do |attr|
    attr.input_type = :file_upload
    attr.category_key = 'economic_capacity'
    attr.subcategory_key = 'financial_data'
    attr.from_api = false
    attr.required = false
  end
end

def create_prior_contract_breach_attribute
  MarketAttribute.find_or_create_by(key: 'prior_contract_breach') do |attr|
    attr.input_type = :checkbox
    attr.category_key = 'exclusion_criteria'
    attr.subcategory_key = 'buyer_discretion'
    attr.from_api = false
    attr.required = false
  end
end

def create_undue_influence_attribute
  MarketAttribute.find_or_create_by(key: 'undue_influence') do |attr|
    attr.input_type = :checkbox
    attr.category_key = 'exclusion_criteria'
    attr.subcategory_key = 'transparency_competition'
    attr.from_api = false
    attr.required = false
  end
end

def create_defense_supply_chain_attribute
  MarketAttribute.find_or_create_by(key: 'defense_supply_chain') do |attr|
    attr.input_type = :file_upload
    attr.category_key = 'defense_security'
    attr.subcategory_key = 'defense_requirements'
    attr.from_api = false
    attr.required = true
  end
end

def associate_attributes_with_market_types(market_types, attributes)
  required_attrs = build_required_attributes(attributes)
  optional_attrs = build_optional_attributes(attributes)

  associate_attributes(market_types[:supplies], required_attrs + optional_attrs)
  associate_attributes(market_types[:defense], required_attrs + [attributes[:defense_supply_chain]])

  [market_types[:services], market_types[:works]].each do |market_type|
    associate_attributes(market_type, required_attrs + optional_attrs)
  end
end

def build_required_attributes(attributes)
  [attributes[:siret], attributes[:company_name], attributes[:criminal_conviction]]
end

def build_optional_attributes(attributes)
  [attributes[:annual_turnover], attributes[:prior_contract_breach], attributes[:undue_influence]]
end

def associate_attributes(market_type, attributes)
  existing_attributes = market_type.market_attributes.to_set
  attributes.each do |attr|
    market_type.market_attributes << attr unless existing_attributes.include?(attr)
  end
end
