# frozen_string_literal: true

module OptionalFieldsValidation
  extend ActiveSupport::Concern

  included do
    validate :selected_fields_are_valid_keys
    validate :selected_fields_are_available_for_market_type
    validate :selected_fields_are_appropriate_for_defense_status
    validate :no_duplicate_selected_fields

    before_save :normalize_selected_optional_fields
  end

  private

  def selected_fields_are_valid_keys
    return if selected_optional_fields.blank?

    service = field_configuration_service
    all_valid_keys = service.all_fields.map(&:key)
    invalid_keys = selected_optional_fields - all_valid_keys

    return if invalid_keys.empty?

    errors.add(:selected_optional_fields,
      "contains invalid field keys: #{invalid_keys.join(', ')}")
  end

  def selected_fields_are_available_for_market_type
    return if selected_optional_fields.blank?

    service = field_configuration_service
    available_keys = service.effective_optional_fields.map(&:key)
    unavailable_keys = selected_optional_fields - available_keys

    return if unavailable_keys.empty?

    errors.add(:selected_optional_fields,
      "contains fields not available for market type '#{market_type}' " \
      "#{defense_industry? ? 'with' : 'without'} defense industry: #{unavailable_keys.join(', ')}")
  end

  def selected_fields_are_appropriate_for_defense_status
    return if selected_optional_fields.blank? || defense_industry?

    validate_defense_fields_not_selected
  end

  def validate_defense_fields_not_selected
    service = field_configuration_service
    defense_fields = service.all_fields.select(&:optional_for_defense?).map(&:key)
    inappropriate_fields = selected_optional_fields & defense_fields

    return if inappropriate_fields.empty?

    errors.add(:selected_optional_fields,
      "contains defense industry fields but defense_industry is false: #{inappropriate_fields.join(', ')}")
  end

  def no_duplicate_selected_fields
    return if selected_optional_fields.blank?

    duplicates = selected_optional_fields.group_by(&:itself)
      .select { |_, v| v.size > 1 }
      .keys

    return if duplicates.empty?

    errors.add(:selected_optional_fields, "contains duplicate entries: #{duplicates.join(', ')}")
  end

  def normalize_selected_optional_fields
    return if selected_optional_fields.blank?

    self.selected_optional_fields = selected_optional_fields
      .compact
      .compact_blank
      .map(&:to_s)
      .uniq
      .sort
  end

  def field_configuration_service
    @field_configuration_service ||= FieldConfigurationService.new(
      market_type: market_type,
      defense_industry: defense_industry?
    )
  end
end
