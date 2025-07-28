module FormFieldConfiguration
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/BlockLength
  class_methods do
    def configuration
      @configuration ||= load_configuration
    end

    private

    def load_configuration
      merged_config = {}

      load_config_file('requirements.yml') { |config| merged_config.merge!(config) }
      load_config_file('field_categories.yml') { |config| merged_config[:field_categories] = config }
      load_config_file('source_types.yml') { |config| merged_config[:source_types] = config }
      load_config_file('field_types.yml') { |config| merged_config[:available_field_types] = config }

      deep_symbolize_config(merged_config)
    end

    def load_config_file(filename)
      config_path = Rails.root.join('config/form_fields', filename)
      config = YAML.load_file(config_path, aliases: true)
      environment_config = config[Rails.env] || config['development']
      yield(environment_config)
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
  # rubocop:enable Metrics/BlockLength

  def market_type_requirements
    self.class.configuration[:market_type_requirements]
  end

  def defense_requirements
    self.class.configuration[:defense_requirements]
  end

  def field_categories
    self.class.configuration[:field_categories]
  end

  def source_types
    self.class.configuration[:source_types]
  end

  def available_field_types
    self.class.configuration[:available_field_types]
  end

  def effective_required_fields
    base_fields = market_type_requirements.dig(market_type.to_sym, :required_fields) || []

    if defense?
      defense_fields = defense_requirements[:required_fields] || []
      (base_fields + defense_fields).uniq
    else
      base_fields
    end
  end

  def effective_optional_fields
    base_fields = market_type_requirements.dig(market_type.to_sym, :available_optional_fields) || []

    if defense?
      defense_fields = defense_requirements[:available_optional_fields] || []
      (base_fields + defense_fields).uniq
    else
      base_fields
    end
  end

  def fields_by_category(field_keys)
    field_keys
      .select { |key| available_field_types[key.to_sym] }
      .group_by { |key| available_field_types[key.to_sym][:category] }
  end
end
