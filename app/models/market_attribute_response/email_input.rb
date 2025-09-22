class MarketAttributeResponse::EmailInput < MarketAttributeResponse::TextInput
  validate :email_format

  private

  def email_format
    validate_text_format(URI::MailTo::EMAIL_REGEXP, :invalid)
  end
end
