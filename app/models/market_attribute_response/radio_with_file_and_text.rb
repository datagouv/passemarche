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
    return unless value.is_a?(Hash)

    clean_text_field
    validate_documents_consistency
    validate_text_consistency
  end

  def clean_text_field
    value.delete('text') if radio_no?
    value['text'] = value['text'].to_s if value['text'] && !value['text'].is_a?(String)
  end

  def validate_documents_consistency
    errors.add(:documents, :not_allowed) if radio_no? && documents.attached?
  end

  def validate_text_consistency
    errors.add(:value, :invalid) if radio_no? && value['text'].present?
  end
end
