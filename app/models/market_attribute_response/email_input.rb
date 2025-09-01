class MarketAttributeResponse::EmailInput < MarketAttributeResponse::TextInput
  validates :text, format: { with: URI::MailTo::EMAIL_REGEXP, message: :invalid }
end
