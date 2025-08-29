class MarketAttributeResponse::Checkbox < MarketAttributeResponse
  def value_checked
    value&.dig('checked') || false
  end

  def value_checked=(checked)
    self.value = (value || {}).merge('checked' => checked)
  end

  protected

  def json_schema
    {
      type: 'object',
      required: ['checked'],
      properties: {
        checked: { type: 'boolean' }
      },
      additionalProperties: false
    }
  end
end
