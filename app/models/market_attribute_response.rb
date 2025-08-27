class MarketAttributeResponse < ApplicationRecord
  belongs_to :market_application
  belongs_to :market_attribute

  def self.find_sti_class(type_name)
    case type_name
    when 'Checkbox'
      MarketAttributeResponse::Checkbox
    when 'TextInput'
      MarketAttributeResponse::TextInput
    when 'FileUpload'
      MarketAttributeResponse::FileUpload
    else
      super
    end
  end

  def self.sti_name
    name.demodulize
  end
end
