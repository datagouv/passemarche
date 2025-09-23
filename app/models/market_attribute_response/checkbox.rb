class MarketAttributeResponse::Checkbox < MarketAttributeResponse
  include MarketAttributeResponse::CheckboxFieldBehavior
  include MarketAttributeResponse::JsonValidatable

  def self.json_schema_properties
    ['checked']
  end

  def self.json_schema_required
    ['checked']
  end

  def self.json_schema_error_field
    :checked
  end
end
