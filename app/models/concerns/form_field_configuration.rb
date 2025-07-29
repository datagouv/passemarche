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

  def source_types
    I18n.t('form_fields.source_types')
  end

  def available_field_types
    self.class.configuration[:available_field_types]
  end

  def effective_required_fields
    fields = []

    available_field_types.each do |field_key, config|
      # Add if required for this market type
      fields << field_key.to_s if config[:required_for]&.include?(market_type.to_s)

      # Add if defense required and this is defense industry
      fields << field_key.to_s if defense_industry? && config[:defense_required]
    end

    fields.uniq
  end

  def effective_optional_fields
    fields = []

    available_field_types.each do |field_key, config|
      # Add if optional for this market type
      fields << field_key.to_s if config[:optional_for]&.include?(market_type.to_s)

      # Add if defense optional and this is defense industry
      fields << field_key.to_s if defense_industry? && config[:defense_optional]
    end

    fields.uniq
  end

  def all_fields
    (effective_required_fields + effective_optional_fields).uniq
  end

  def fields_by_category_and_subcategory(field_keys)
    field_keys
      .filter_map { |key| field_with_category_info(key) }
      .group_by { |field_info| field_info[:category] }
      .transform_values { |fields| group_by_subcategory(fields) }
  end

  def should_display_subcategory?(category_subcategories)
    category_subcategories.keys.size > 1
  end

  private

  def field_with_category_info(key)
    field_config = available_field_types[key.to_sym]
    return unless field_config

    {
      key: key,
      category: field_config[:category],
      subcategory: field_config[:subcategory]
    }
  end

  def group_by_subcategory(fields)
    fields
      .group_by { |field| field[:subcategory] }
      .transform_values { |grouped_fields| grouped_fields.map { |f| f[:key] } }
  end
end
