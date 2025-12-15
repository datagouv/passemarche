# frozen_string_literal: true

class MarketAttributeResponse::FileOrTextareaComponent < MarketAttributeResponse::BaseComponent
  delegate :documents, to: :market_attribute_response
  delegate :attached?, to: :documents, prefix: :documents

  def text_value
    market_attribute_response.value&.[]('text') || ''
  end

  def text?
    text_value.present?
  end

  def formatted_text_value
    return '' if text_value.blank?

    helpers.simple_format(text_value)
  end

  def no_content_message
    'Aucune description ni fichier fourni'
  end

  def no_files_message
    'Aucun fichier téléchargé'
  end

  def naming_service
    @naming_service ||= DocumentNamingService.new(market_attribute_response.market_application)
  end

  def errors?
    market_attribute_response.errors[:value].any? ||
      market_attribute_response.errors[:text].any? ||
      market_attribute_response.errors[:documents].any?
  end

  def error_messages
    market_attribute_response.errors[:value] +
      market_attribute_response.errors[:text] +
      market_attribute_response.errors[:documents]
  end
end
