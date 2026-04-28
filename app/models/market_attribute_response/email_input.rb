class MarketAttributeResponse::EmailInput < MarketAttributeResponse::TextInput
  validates :text, email: true, allow_blank: true
end
