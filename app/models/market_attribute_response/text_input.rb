class MarketAttributeResponse::TextInput < MarketAttributeResponse
  TEXT_MAX_LENGTH = 10_000

  store_accessor :value, :text

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
