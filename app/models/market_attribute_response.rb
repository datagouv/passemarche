require 'json-schema'

class MarketAttributeResponse < ApplicationRecord
  belongs_to :market_application
  belongs_to :market_attribute

  validates :type, presence: true, inclusion: { in: %w[Checkbox Textarea TextInput FileUpload] }
  validates :type, presence: true, inclusion: { in: %w[Checkbox Textarea TextInput FileUpload EmailInput] }

  validate :validate_json_schema, unless: :new_record?

  def self.find_sti_class(type_name)
    case type_name
    when 'Checkbox'
      MarketAttributeResponse::Checkbox
    when 'Textarea'
      MarketAttributeResponse::Textarea
    when 'TextInput'
      MarketAttributeResponse::TextInput
    when 'FileUpload'
      MarketAttributeResponse::FileUpload
    when 'EmailInput'
      MarketAttributeResponse::EmailInput
    else
      super
    end
  end

  def self.sti_name
    name.demodulize
  end

  protected

  def json_schema
    raise NotImplementedError, "#{self.class.name} must define json_schema"
  end

  private

  def validate_json_schema
    return unless respond_to?(:json_schema, true)

    value_to_validate = value || {}

    schema = json_schema
    return unless schema

    errors_list = JSON::Validator.fully_validate(schema, value_to_validate)
    errors_list.each do |error_message|
      errors.add(:value, error_message)
    end
  rescue NotImplementedError
    # Subclass doesn't implement json_schema, skip validation
  end
end
