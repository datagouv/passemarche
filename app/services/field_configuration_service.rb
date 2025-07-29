# frozen_string_literal: true

class FieldConfigurationService
  def initialize(market_type:, defense_industry:)
    @market_type = market_type.to_s
    @defense_industry = defense_industry
    @field_requirement = FieldRequirement.new(
      market_type: @market_type,
      defense_industry: @defense_industry
    )
  end

  def effective_required_fields
    fields_by_keys(@field_requirement.required_field_keys)
  end

  def effective_optional_fields
    fields_by_keys(@field_requirement.optional_field_keys)
  end

  def all_fields
    @all_fields ||= load_fields_from_config
  end

  def field_by_key(key)
    all_fields.find { |field| field.key == key.to_s }
  end

  def fields_by_keys(keys)
    keys.filter_map { |key| field_by_key(key) }
  end

  attr_reader :field_requirement

  private

  def load_fields_from_config
    config = load_field_types_config
    config.map do |key, attributes|
      Field.new(attributes.merge(key: key.to_s))
    end
  end

  def load_field_types_config
    Rails.application.config_for('form_fields/field_types')
  end
end
