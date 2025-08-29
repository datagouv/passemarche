class MarketAttributeResponse::TextInput < MarketAttributeResponse
  TEXT_MAX_LENGTH = 10_000

  def value_text
    value&.dig('text') || ''
  end

  def value_text=(text)
    self.value = (value || {}).merge('text' => text)
  end

  protected

  def json_schema
    {
      type: 'object',
      required: ['text'],
      properties: {
        text: {
          type: 'string',
          maxLength: TEXT_MAX_LENGTH
        }
      },
      additionalProperties: false
    }
  end
end
