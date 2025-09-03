class MarketAttributeResponse < ApplicationRecord
  belongs_to :market_application
  belongs_to :market_attribute

  validates :type,
            presence: true,
            inclusion: {
              in: %w[
                Checkbox
                Textarea
                TextInput
                FileUpload
                EmailInput
                PhoneInput
              ]
            }

  STI_CLASS_MAP = {
    'Checkbox'   => MarketAttributeResponse::Checkbox,
    'Textarea'   => MarketAttributeResponse::Textarea,
    'TextInput'  => MarketAttributeResponse::TextInput,
    'FileUpload' => MarketAttributeResponse::FileUpload,
    'EmailInput' => MarketAttributeResponse::EmailInput,
    'PhoneInput' => MarketAttributeResponse::PhoneInput
  }.freeze

  def self.find_sti_class(type_name)
    STI_CLASS_MAP[type_name] || super
  end

  def self.sti_name
    name.demodulize
  end
end
