class MarketAttributeResponse::Checkbox < MarketAttributeResponse
  store_accessor :value, :checked

  def checked=(val)
    super(ActiveModel::Type::Boolean.new.cast(val))
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
