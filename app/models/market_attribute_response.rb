class MarketAttributeResponse < ApplicationRecord
  belongs_to :market_application
  belongs_to :market_attribute

  # Simple mapping from input_type to STI class name
  INPUT_TYPE_MAP = {
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

  def self.build_for_attribute(market_attribute, params = {})
    sti_class_name = INPUT_TYPE_MAP[market_attribute.input_type]
    raise "Unknown input type: #{market_attribute.input_type}" unless sti_class_name

    klass = "MarketAttributeResponse::#{sti_class_name}".constantize
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
