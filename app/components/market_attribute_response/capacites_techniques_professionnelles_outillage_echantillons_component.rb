# frozen_string_literal: true

# Component for displaying/editing samples (echantillons) with descriptions and files
# Maps to input_type: :capacites_techniques_professionnelles_outillage_echantillons
class MarketAttributeResponse::CapacitesTechniquesProfessionnellesOutillageEchantillonsComponent < MarketAttributeResponse::BaseComponent
  delegate :echantillons, :echantillons_ordered, :get_item_field, :echantillon_fichiers, to: :market_attribute_response

  def data?
    echantillons.present? && echantillons.values.any? { |e| echantillon_has_data?(e) }
  end

  def echantillon_has_data?(echantillon)
    return false unless echantillon.is_a?(Hash)

    echantillon.any? { |_k, v| v.present? }
  end

  def echantillons_with_data
    echantillons_ordered.select { |_timestamp, echantillon| echantillon_has_data?(echantillon) }
  end

  def errors?
    market_attribute_response.errors[:value].any?
  end

  def value_error_messages
    market_attribute_response.errors[:value]
  end

  def naming_service
    @naming_service ||= DocumentNamingService.new(market_attribute_response.market_application)
  end

  def add_button_text
    'Ajouter un échantillon'
  end

  def no_data_message
    'Aucun échantillon renseigné'
  end
end
