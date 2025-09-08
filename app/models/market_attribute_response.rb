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
    'Phone' => 'MarketAttributeResponse::PhoneInput'
  }.freeze

  validates :type, presence: true, inclusion: { in: STI_CLASS_MAP.keys }

  def self.find_sti_class(type_name)
    STI_CLASS_MAP[type_name]&.constantize || super
  end

  def self.sti_name
    name.demodulize
  end
end
