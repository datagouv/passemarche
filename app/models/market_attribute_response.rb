class MarketAttributeResponse < ApplicationRecord
  belongs_to :market_application
  belongs_to :market_attribute

  STI_CLASS_MAP = {
    'Checkbox' => 'MarketAttributeResponse::Checkbox',
    'CheckboxWithDocument' => 'MarketAttributeResponse::CheckboxWithDocument',
    'Textarea' => 'MarketAttributeResponse::Textarea',
    'TextInput' => 'MarketAttributeResponse::TextInput',
    'FileUpload' => 'MarketAttributeResponse::FileUpload',
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

  validates :type, presence: true, inclusion: { in: STI_CLASS_MAP.keys }

  before_validation :set_type_from_market_attribute, on: :create

  def self.find_sti_class(type_name)
    STI_CLASS_MAP[type_name]&.constantize || super
  end

  def self.sti_name
    name.demodulize
  end

  def self.type_from_input_type(input_type)
    INPUT_TYPE_TO_STI_TYPE[input_type.to_s]
  end

  private

  def set_type_from_market_attribute
    return if type.present?
    return unless market_attribute

    self.type = self.class.type_from_input_type(market_attribute.input_type)
  end
end
