# frozen_string_literal: true

class MarketAttributeResponse::RadioWithJustificationRequired < MarketAttributeResponse
  include MarketAttributeResponse::RadioFieldBehavior
  include MarketAttributeResponse::TextFieldBehavior
  include MarketAttributeResponse::FileAttachable
  include MarketAttributeResponse::JsonValidatable

  validate :conditional_fields_based_on_radio

  def self.json_schema_properties
    %w[radio_choice text]
  end

  def self.json_schema_required
    []
  end

  def self.json_schema_error_field
    :value
  end

  private

  def conditional_fields_based_on_radio
    return unless radio_no?

    errors.add(:documents, :required) unless documents.attached?
    errors.add(:value, :invalid) if text.present?
  end
end
