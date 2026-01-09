# frozen_string_literal: true

class MarketAttributeResponse::InlineFileUploadComponent < MarketAttributeResponse::BaseComponent
  delegate :documents, to: :market_attribute_response
  delegate :attached?, to: :documents, prefix: :documents

  def no_documents_message
    'Aucun fichier téléchargé'
  end

  def naming_service
    @naming_service ||= DocumentNamingService.new(market_attribute_response.market_application)
  end

  def qualiopi_metadata?
    market_attribute_response.respond_to?(:qualiopi_metadata?) &&
      market_attribute_response.qualiopi_metadata?
  end

  def errors?
    market_attribute_response.errors[:documents].any?
  end

  def error_messages
    market_attribute_response.errors[:documents]
  end

  def not_provided_message
    'Non renseigné'
  end
end
