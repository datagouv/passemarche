# frozen_string_literal: true

class MarketAttributeResponse::CapaciteEconomiqueFinanciereChiffreAffairesGlobalAnnuel < MarketAttributeResponse
  include MarketAttributeResponse::JsonValidatable

  # Expected JSON structure:
  # {
  #   "year_1": {
  #     "turnover": 123456,
  #     "market_percentage": 75,
  #     "fiscal_year_end": "2023-12-31"
  #   },
  #   "year_2": {
  #     "turnover": 234567,
  #     "market_percentage": 80,
  #     "fiscal_year_end": "2022-12-31"
  #   },
  #   "year_3": {
  #     "turnover": 345678,
  #     "market_percentage": 85,
  #     "fiscal_year_end": "2021-12-31"
  #   }
  # }

  def self.json_schema_properties
    %w[year_1 year_2 year_3]
  end

  def self.json_schema_required
    %w[year_1 year_2 year_3]
  end

  def self.json_schema_error_field
    :value
  end
end
