class MarketAttributeResponse < ApplicationRecord
  belongs_to :market_application
  belongs_to :market_attribute

  validates :type,
    presence: true,
    inclusion: {
      in: %w[
        Checkbox
        EmailInput
        FileUpload
        PhoneInput
        TextInput
        Textarea
      ]
    }

  STI_CLASS_MAP = {
    'Checkbox' => MarketAttributeResponse::Checkbox,
    'EmailInput' => MarketAttributeResponse::EmailInput,
    'FileUpload' => MarketAttributeResponse::FileUpload,
    'PhoneInput' => MarketAttributeResponse::PhoneInput,
    'TextInput' => MarketAttributeResponse::TextInput,
    'Textarea' => MarketAttributeResponse::Textarea
  }.freeze

  def self.find_sti_class(type_name)
    STI_CLASS_MAP[type_name] || super
  end

  def self.sti_name
    name.demodulize
  end
end
