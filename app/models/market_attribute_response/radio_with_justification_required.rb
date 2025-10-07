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
    if radio_no?
      # When "no" (non-compliant), documents are REQUIRED
      errors.add(:documents, :required) unless documents.attached?
      # Text and extra documents in value hash are not allowed
      errors.add(:value, :invalid) if text.present?
    elsif radio_yes?
      # When "yes" (compliant), text and documents are OPTIONAL
      # No validation errors for optional fields
    end
  end
end
