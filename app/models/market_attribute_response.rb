class MarketAttributeResponse < ApplicationRecord
  belongs_to :market_application
  belongs_to :market_attribute

  validates :type, presence: true, inclusion: { in: %w[Checkbox Textarea TextInput FileUpload EmailInput] }

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
end
