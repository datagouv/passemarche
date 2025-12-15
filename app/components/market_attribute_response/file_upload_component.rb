# frozen_string_literal: true

class MarketAttributeResponse::FileUploadComponent < MarketAttributeResponse::BaseComponent
  delegate :documents, to: :market_attribute_response
  delegate :attached?, to: :documents, prefix: :documents

  def no_documents_message
    'Aucun fichier téléchargé'
  end

  def naming_service
    @naming_service ||= DocumentNamingService.new(market_attribute_response.market_application)
  end

  def errors?
    market_attribute_response.errors[:documents].any?
  end

  def error_messages
    market_attribute_response.errors[:documents]
  end
end
