class MarketAttributeResponse::FileOrTextarea < MarketAttributeResponse
  include MarketAttributeResponse::FileAttachable
  include MarketAttributeResponse::JsonValidatable
  include MarketAttributeResponse::TextValidatable

  def self.json_schema_properties
    %i[text]
  end

  def self.json_schema_required
    []
  end

  def self.json_schema_error_field
    :value
  end
end
