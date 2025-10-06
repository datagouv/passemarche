# frozen_string_literal: true

class MarketAttributeResponse::RadioWithFileAndText < MarketAttributeResponse
  include MarketAttributeResponse::JsonValidatable

  store_accessor :value

  def self.json_schema_properties
    []
  end

  def self.json_schema_required
    []
  end

  def self.json_schema_error_field
    :value
  end
end
