# frozen_string_literal: true

module MarketAttributeResponse::TextValidatable
  extend ActiveSupport::Concern

  TEXT_MAX_LENGTH = 10_000

  included do
    store_accessor :value, :text
    validates :text, length: { maximum: TEXT_MAX_LENGTH }
    validate :text_must_be_string
    validate :text_field_required
    validate :text_additional_properties_valid
  end

  delegate :present?, to: :text, prefix: true

  def validate_text_format(format, error_message)
    return if text.blank?

    errors.add(:text, error_message) unless text.match?(format)
  end

  private

  def text_must_be_string
    return if text.nil? || text.is_a?(String)

    errors.add(:text, I18n.t('activerecord.errors.json_schema.wrong_type'))
  end

  def text_field_required
    return unless value.blank? || !value.key?('text')

    errors.add(:text, I18n.t('activerecord.errors.json_schema.required'))
  end

  def text_additional_properties_valid
    return if value.blank?

    allowed_keys = ['text']
    extra_keys = value.keys - allowed_keys

    return if extra_keys.empty?

    errors.add(:text, I18n.t('activerecord.errors.json_schema.additional_properties'))
  end
end
