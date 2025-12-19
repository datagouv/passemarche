# frozen_string_literal: true

class MarketAttributeResponse::CapaciteEconomiqueFinanciereEffectifsMoyensAnnuels < MarketAttributeResponse
  include MarketAttributeResponse::JsonValidatable
  include MarketAttributeResponse::YearlyDataValidatable

  YEAR_KEYS = %w[year_1 year_2 year_3].freeze
  STAFF_FIELD = 'average_staff'
  YEAR_FIELD = 'year'

  # Expected JSON structure:
  # {
  #   "year_1": { "year": 2023, "average_staff": 25 },
  #   "year_2": { "year": 2022, "average_staff": 30 },
  #   "year_3": { "year": 2021, "average_staff": 28 }
  # }

  def self.json_schema_properties
    YEAR_KEYS
  end

  def self.json_schema_required
    []
  end

  def self.json_schema_error_field
    :value
  end

  validate :validate_year_data_structure
  validate :validate_staff_and_year_fields

  YEAR_KEYS.each do |year_key|
    define_method "#{year_key}_#{STAFF_FIELD}" do
      value&.dig(year_key, STAFF_FIELD)
    end

    define_method "#{year_key}_#{STAFF_FIELD}=" do |val|
      self.value ||= {}
      value[year_key] ||= {}
      value[year_key][STAFF_FIELD] = coerce_field_value(val)
    end

    define_method "#{year_key}_#{YEAR_FIELD}" do
      value&.dig(year_key, YEAR_FIELD)
    end

    define_method "#{year_key}_#{YEAR_FIELD}=" do |val|
      self.value ||= {}
      value[year_key] ||= {}
      value[year_key][YEAR_FIELD] = coerce_year_value(val)
    end
  end

  private

  def coerce_field_value(val)
    val.presence&.to_i
  end

  def coerce_year_value(val)
    val.presence&.to_i
  end

  def validate_year_data_structure
    return if value.blank?

    YEAR_KEYS.each do |year_key|
      year_data = value[year_key]
      next if year_data.blank?

      errors.add(:value, "#{year_key} must be a hash") unless year_data.is_a?(Hash)
    end
  end

  def validate_staff_and_year_fields
    return if value.blank?

    YEAR_KEYS.each do |year_key|
      year_data = value[year_key]
      next if year_data.blank? || !year_has_any_data?(year_data)

      validate_staff_value(year_key, year_data[STAFF_FIELD])
      validate_year_value(year_key, year_data[YEAR_FIELD])
    end
  end

  def validate_staff_value(year_key, staff)
    return if staff.blank? || valid_positive_integer?(staff)

    errors.add(:value, "#{year_key}.average_staff must be a positive integer")
  end

  def validate_year_value(year_key, year)
    return if year.blank? || valid_year?(year)

    errors.add(:value, "#{year_key}.year must be a valid year")
  end

  def valid_year?(value)
    value.is_a?(Integer) && value >= 2000 && value <= Time.current.year
  end
end
