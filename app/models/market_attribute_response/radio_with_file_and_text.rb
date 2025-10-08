# frozen_string_literal: true

class MarketAttributeResponse::RadioWithFileAndText < MarketAttributeResponse
  include MarketAttributeResponse::RadioFieldBehavior
  include MarketAttributeResponse::TextFieldBehavior
  include MarketAttributeResponse::FileAttachable
  include MarketAttributeResponse::JsonValidatable

  validate :conditional_fields_only_when_yes

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

  def conditional_fields_only_when_yes
    return unless radio_no?

    errors.add(:value, :invalid) if text.present?
    errors.add(:documents, :not_allowed) if documents.attached?
  end
end
