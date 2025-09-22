# frozen_string_literal: true

module MarketAttributeResponse::JsonValidatable
  extend ActiveSupport::Concern

  class_methods do
    # Override these methods in classes that include this concern
    def json_schema_properties
      raise NotImplementedError, "#{self} must implement json_schema_properties class method"
    end

    def json_schema_required
      raise NotImplementedError, "#{self} must implement json_schema_required class method"
    end

    def json_schema_error_field
      raise NotImplementedError, "#{self} must implement json_schema_error_field class method"
    end
  end

  included do
    validate :validate_json_structure
  end

  private

  def validate_json_structure
    validate_required_fields
    validate_allowed_properties if value.present?
  end

  def validate_required_fields
    self.class.json_schema_required.each do |field|
      errors.add(field, I18n.t('activerecord.errors.json_schema.required')) if value.blank? || !value.key?(field.to_s)
    end
  end

  def validate_allowed_properties
    return unless self.class.json_schema_properties.any?

    allowed_keys = self.class.json_schema_properties.map(&:to_s)
    extra_keys = value.keys - allowed_keys

    return if extra_keys.empty?

    error_field = self.class.json_schema_error_field
    errors.add(error_field, I18n.t('activerecord.errors.json_schema.additional_properties'))
  end
end
