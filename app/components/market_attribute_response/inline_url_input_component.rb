# frozen_string_literal: true

class MarketAttributeResponse::InlineUrlInputComponent < MarketAttributeResponse::BaseComponent
  OPQIBI_KEY = 'capacites_techniques_professionnelles_certificats_opqibi'
  FRANCE_COMPETENCES_KEY = 'capacites_techniques_professionnelles_certificats_france_competences'

  def text_value
    market_attribute_response.text || ''
  end

  def display_value
    return 'Certificat non renseigné' if text_value.blank?

    text_value
  end

  def opqibi_metadata?
    market_attribute_response.respond_to?(:opqibi_metadata?) &&
      market_attribute_response.opqibi_metadata?
  end

  def france_competence_metadata?
    market_attribute_response.respond_to?(:france_competence_metadata?) &&
      market_attribute_response.france_competence_metadata?
  end

  def opqibi_field?
    market_attribute_response.market_attribute.key == OPQIBI_KEY
  end

  def france_competences_field?
    market_attribute_response.market_attribute.key == FRANCE_COMPETENCES_KEY
  end

  def opqibi_help_url
    'https://www.opqibi.com/recherche-plus'
  end

  def france_competences_help_url
    'https://www.francecompetences.fr/recherche-resultats/'
  end

  def errors?
    market_attribute_response.errors[:text].any?
  end

  def error_messages
    market_attribute_response.errors[:text]
  end

  def input_css_class
    css = 'fr-input'
    css += ' fr-input--error' if errors?
    css
  end

  def input_id
    "certificat-#{market_attribute_response.id}-url"
  end

  delegate :formatted_date_delivrance, :duree_validite_certificat, to: :market_attribute_response
end
