# frozen_string_literal: true

class MarketAttributeResponse::EmailInputComponent < MarketAttributeResponse::BaseComponent
  def text_value
    market_attribute_response.text || ''
  end

  def display_value
    return 'Non renseigné' if text_value.blank?

    text_value
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
