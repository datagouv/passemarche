# frozen_string_literal: true

class MarketAttributeResponse::TextInputComponent < MarketAttributeResponse::BaseComponent
  def text_value
    market_attribute_response.value&.dig('text') || ''
  end

  def display_value
    text_value.presence || 'Non renseigné'
  end

  def errors?
    market_attribute_response.errors[:text].any?
  end

  def error_messages
    market_attribute_response.errors[:text]
  end

  def input_group_css_class
    css = 'fr-input-group'
    css += ' fr-input-group--error' if errors?
    css
  end

  def input_css_class
    css = 'fr-input'
    css += ' fr-input--error' if errors?
    css
  end
end
