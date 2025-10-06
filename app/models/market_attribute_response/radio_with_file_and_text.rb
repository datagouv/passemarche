# frozen_string_literal: true

class MarketAttributeResponse::RadioWithFileAndText < MarketAttributeResponse
  include MarketAttributeResponse::RadioFieldBehavior
  include MarketAttributeResponse::TextFieldBehavior
  include MarketAttributeResponse::FileAttachable
  include MarketAttributeResponse::JsonValidatable

  def self.json_schema_properties
    %w[radio_choice text]
  end

  def self.json_schema_required
    []
  end

  def self.json_schema_error_field
    :value
  end
end
