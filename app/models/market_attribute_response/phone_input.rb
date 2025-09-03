class MarketAttributeResponse::PhoneInput < MarketAttributeResponse::TextInput
  TEXT_MAX_LENGTH = 15

  validates :text,
    length: { maximum: TEXT_MAX_LENGTH, too_long: :too_long },
    format: {
      with: /\A[+0-9\s\-\(\)]*\z/,
      message: :invalid
    },
    allow_blank: true
end
