# frozen_string_literal: true

# Component for displaying/editing past projects/deliveries (realisations)
# Maps to input_type: :realisations_livraisons
class MarketAttributeResponse::RealisationsLivraisonsComponent < MarketAttributeResponse::BaseComponent
  include ActionView::Helpers::NumberHelper

  delegate :realisations, :realisations_ordered, :get_item_field, :realisation_attestations, to: :market_attribute_response

  def data?
    realisations.present? && realisations.values.any? { |r| realisation_has_data?(r) }
  end

  def realisation_has_data?(realisation)
    return false unless realisation.is_a?(Hash)

    realisation.any? { |_k, v| v.present? }
  end

  def realisations_with_data
    realisations_ordered.select { |_timestamp, realisation| realisation_has_data?(realisation) }
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
    'Ajouter une réalisation'
  end

  def no_data_message
    'Aucune réalisation renseignée'
  end

  def formatted_date(date_str)
    return nil if date_str.blank?

    I18n.l(Date.parse(date_str), format: :long)
  rescue ArgumentError
    date_str
  end

  def formatted_montant(montant)
    return nil if montant.blank?

    number_to_currency(montant, unit: '', separator: ',', delimiter: ' ', format: '%n', precision: 0)
  end
end
