# frozen_string_literal: true

class MarketAttributeResponse::CapaciteEconomiqueFinanciereChiffreAffairesGlobalAnnuel < MarketAttributeResponse
  include MarketAttributeResponse::JsonValidatable

  YEAR_KEYS = %w[year_1 year_2 year_3].freeze
  FIELD_NAMES = %w[turnover market_percentage fiscal_year_end].freeze

  # Expected JSON structure:
  # {
  #   "year_1": { "turnover": 123456, "market_percentage": 75, "fiscal_year_end": "2023-12-31" },
  #   "year_2": { "turnover": 234567, "market_percentage": 80, "fiscal_year_end": "2022-12-31" },
  #   "year_3": { "turnover": 345678, "market_percentage": 85, "fiscal_year_end": "2021-12-31" }
  # }

  def self.json_schema_properties
    %w[year_1 year_2 year_3]
  end

  def self.json_schema_required
    []
  end

  def self.json_schema_error_field
    :value
  end

  validate :validate_year_data_structure
  validate :validate_numeric_fields
  validate :validate_fiscal_year_dates

  YEAR_KEYS.each do |year_key|
    FIELD_NAMES.each do |field_name|
      define_method "#{year_key}_#{field_name}" do
        value&.dig(year_key, field_name)
      end

      define_method "#{year_key}_#{field_name}=" do |val|
        self.value ||= {}
        value[year_key] ||= {}
        value[year_key][field_name] = coerce_field_value(field_name, val)
      end
    end
  end

  private

  def coerce_field_value(field_name, val)
    if %w[turnover market_percentage].include?(field_name)
      val.present? ? val.to_i : nil
    else
      val.presence
    end
  end

  def validate_year_data_structure
    return if value.blank?

    YEAR_KEYS.each do |year_key|
      year_data = value[year_key]
      next if year_data.blank?

      unless year_data.is_a?(Hash)
        errors.add(:value, "#{year_key} must be a hash")
        next
      end

      next unless year_has_any_data?(year_data)

      FIELD_NAMES.each do |field|
        errors.add(:value, "#{year_key}.#{field} is required") if year_data[field].nil?
      end
    end
  end

  def year_has_any_data?(year_data)
    return false unless year_data.is_a?(Hash)

    year_data.values.any?(&:present?)
  end

  def validate_numeric_fields
    return if value.blank?

    YEAR_KEYS.each do |year_key|
      year_data = value[year_key]
      next if year_data.blank? || !year_has_any_data?(year_data)

      validate_turnover_for_year(year_key, year_data['turnover'])
      validate_percentage_for_year(year_key, year_data['market_percentage'])
    end
  end

  def validate_fiscal_year_dates
    return if value.blank?

    YEAR_KEYS.each do |year_key|
      year_data = value[year_key]
      next if year_data.blank? || !year_has_any_data?(year_data)

      validate_date_for_year(year_key, year_data['fiscal_year_end'])
    end
  end

  def validate_turnover_for_year(year_key, turnover)
    return if turnover.blank?
    return if valid_positive_integer?(turnover)

    errors.add(:value, "#{year_key}.turnover must be a positive integer")
  end

  def validate_percentage_for_year(year_key, percentage)
    return if percentage.nil?
    return if valid_percentage?(percentage)

    errors.add(:value, "#{year_key}.market_percentage must be between 0 and 100")
  end

  def validate_date_for_year(year_key, date_str)
    return if date_str.nil?

    Date.iso8601(date_str)
  rescue ArgumentError
    errors.add(:value, "#{year_key}.fiscal_year_end must be in YYYY-MM-DD format")
  end

  def valid_positive_integer?(value)
    value.is_a?(Integer) && !value.negative?
  end

  def valid_percentage?(value)
    value.is_a?(Integer) && !value.negative? && value <= 100
  end
end
