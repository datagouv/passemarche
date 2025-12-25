# frozen_string_literal: true

# Component for displaying/editing team members (intervenants) with their CVs
# Maps to input_type: :presentation_intervenants
class MarketAttributeResponse::PresentationIntervenantsComponent < MarketAttributeResponse::BaseComponent
  delegate :persons, :persons_ordered, :get_item_field, :person_cv_attachment, :documents, to: :market_attribute_response

  def data?
    persons.present? && persons.values.any? { |p| person_has_data?(p) }
  end

  def person_has_data?(person)
    return false unless person.is_a?(Hash)

    person.any? { |_k, v| v.present? }
  end

  def persons_with_data
    persons_ordered.select { |_timestamp, person| person_has_data?(person) }
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
    'Ajouter un intervenant manuellement'
  end

  def no_data_message
    'Aucune personne renseignée'
  end

  def documents_attached?
    documents.any?
  end
end
