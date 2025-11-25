# frozen_string_literal: true

module MarketAttributeResponse::TextValidatable
  extend ActiveSupport::Concern

  included do
    include MarketAttributeResponse::TextFieldBehavior

    validate :text_additional_properties_valid
  end

  private

  def text_additional_properties_valid
    return if auto?
    return if value.blank?

    allowed_keys = ['text']
    extra_keys = value.keys - allowed_keys

    return if extra_keys.empty?

    errors.add(:text, I18n.t('activerecord.errors.json_schema.additional_properties'))
  end
end
