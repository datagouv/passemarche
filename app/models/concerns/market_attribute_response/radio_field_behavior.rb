# frozen_string_literal: true

module MarketAttributeResponse::RadioFieldBehavior
  extend ActiveSupport::Concern

  RADIO_YES = 'yes'
  RADIO_NO = 'no'
  RADIO_VALUES = [RADIO_YES, RADIO_NO].freeze

  included do
    validates :radio_choice, inclusion: { in: RADIO_VALUES, allow_nil: true }
    validate :radio_choice_must_be_string

    after_initialize :set_default_radio_choice
  end

  def radio_choice=(val)
    normalized = normalize_radio_value(val)
    self.value = if normalized.nil?
                   (value || {}).except('radio_choice')
                 else
                   (value || {}).merge('radio_choice' => normalized)
                 end
    value_will_change! if persisted?
  end

  def radio_choice
    (value || {})['radio_choice']
  end

  def radio_yes?
    radio_choice == RADIO_YES
  end

  def radio_no?
    radio_choice == RADIO_NO
  end

  private

  def set_default_radio_choice
    self.radio_choice ||= RADIO_NO if new_record?
  end

  def normalize_radio_value(val)
    val_str = val.to_s.strip.downcase
    return nil if val_str.blank?
    return RADIO_YES if val_str == RADIO_YES
    return RADIO_NO if val_str == RADIO_NO

    val_str
  end

  def radio_choice_must_be_string
    return if value.blank? || !value.key?('radio_choice')

    raw_choice = value['radio_choice']
    return if raw_choice.is_a?(String)

    errors.add(:radio_choice, :invalid)
  end
end
