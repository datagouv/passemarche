class MarketAttributeResponse::PhoneInput < MarketAttributeResponse::TextInput
  TEXT_MAX_LENGTH = 20
  # Accepting : 01 23 45 67 89, 0123456789, 01-23-45-67-89, +33 1 23 45 67 89, international phone numbers
  # Rejecting : 123456789, 01 23 45 67, 01 23 45 AB 89, ++33 1 23 45 67 89
  PHONE_REGEX = /\A((\+\d{1,3}[\s-]?)|0)[1-9](?:[\s-]?\d{2}){4}\z/

  validates :text,
    length: { maximum: TEXT_MAX_LENGTH, too_long: :too_long },
    format: {
      with: PHONE_REGEX,
      message: :invalid
    }
end
