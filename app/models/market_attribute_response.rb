class MarketAttributeResponse < ApplicationRecord
  belongs_to :market_application
  belongs_to :market_attribute

  STI_CLASS_MAP = {
    'Checkbox' => 'MarketAttributeResponse::Checkbox',
    'CheckboxWithDocument' => 'MarketAttributeResponse::CheckboxWithDocument',
    'Textarea' => 'MarketAttributeResponse::Textarea',
    'TextInput' => 'MarketAttributeResponse::TextInput',
    'FileUpload' => 'MarketAttributeResponse::FileUpload',
    'FileOrTextarea' => 'MarketAttributeResponse::FileOrTextarea',
    'EmailInput' => 'MarketAttributeResponse::EmailInput',
    'PhoneInput' => 'MarketAttributeResponse::PhoneInput'
  }.freeze

  INPUT_TYPE_TO_STI_TYPE = {
    'file_upload' => 'FileUpload',
    'text_input' => 'TextInput',
    'checkbox' => 'Checkbox',
    'textarea' => 'Textarea',
    'email_input' => 'EmailInput',
    'phone_input' => 'PhoneInput',
    'checkbox_with_document' => 'CheckboxWithDocument'
  }.freeze

  validates :type, presence: true, inclusion: { in: INPUT_TYPE_MAP.values }

  before_validation :set_type_from_market_attribute, on: :create

  def self.find_sti_class(type_name)
    "MarketAttributeResponse::#{type_name}".constantize
  end

  def self.sti_class_for_input_type(input_type)
    sti_class_name = INPUT_TYPE_MAP[input_type]
    unless sti_class_name
      valid_types = INPUT_TYPE_MAP.keys.join(', ')
      raise "Unknown input type '#{input_type}'. Valid types are: #{valid_types}"
    end

    "MarketAttributeResponse::#{sti_class_name}".constantize
  end

  def self.build_for_attribute(market_attribute, params = {})
    klass = sti_class_for_input_type(market_attribute.input_type)
    klass.new(params.merge(market_attribute:))
  end

  def self.type_from_input_type(input_type)
    INPUT_TYPE_MAP[input_type]
  end

  def self.sti_name
    name.demodulize
  end

  private

  def set_type_from_market_attribute
    return if type.present?
    return unless market_attribute

    self.type = INPUT_TYPE_MAP[market_attribute.input_type]
  end
end
