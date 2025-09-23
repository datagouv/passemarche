# frozen_string_literal: true

module MarketAttributeResponse::TextFieldBehavior
  extend ActiveSupport::Concern

  TEXT_MAX_LENGTH = 10_000

  included do
    store_accessor :value, :text
    validates :text, length: { maximum: TEXT_MAX_LENGTH }
    validate :text_must_be_string
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
end
