class MarketAttributeResponse::Checkbox < MarketAttributeResponse
  def value_checked
    value&.dig('checked') || false
  end

  def value_checked=(checked)
    self.value = (value || {}).merge('checked' => checked)
  end
end
