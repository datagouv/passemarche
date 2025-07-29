# frozen_string_literal: true

class FieldConfigurationService
  def initialize(market_type:, defense_industry:)
    @market_type = market_type.to_s
    @defense_industry = defense_industry
  end

  def effective_required_fields
    all_fields.select do |field|
      field.required_for_market_type?(@market_type) ||
        (@defense_industry && field.required_for_defense?)
    end
  end

  def effective_optional_fields
    all_fields.select do |field|
      field.optional_for_market_type?(@market_type) ||
        (@defense_industry && field.optional_for_defense?)
    end
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

  private

  def load_fields_from_config
    config = load_yaml_config
    config.map do |key, attributes|
      Field.new(attributes.merge(key: key.to_s))
    end
  end

  def load_yaml_config
    config_path = Rails.root.join('config/form_fields/field_types.yml')
    config = YAML.load_file(config_path, aliases: true)
    environment_config = config[Rails.env] || config['development']
    deep_symbolize_config(environment_config)
  end

  def deep_symbolize_config(hash)
    hash.transform_keys(&:to_sym).transform_values do |value|
      case value
      when Hash
        deep_symbolize_config(value)
      when Array
        value.map { |item| item.is_a?(Hash) ? deep_symbolize_config(item) : item }
      else
        value
      end
    end
  end
end
