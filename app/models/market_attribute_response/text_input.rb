class MarketAttributeResponse::TextInput < MarketAttributeResponse
  def value_text
    value&.dig('text') || ''
  end

  def value_text=(text)
    self.value = (value || {}).merge('text' => text)
  end
end
