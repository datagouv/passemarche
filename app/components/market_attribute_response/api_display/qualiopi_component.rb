# frozen_string_literal: true

class MarketAttributeResponse::ApiDisplay::QualiopiComponent < MarketAttributeResponse::ApiDisplay::BaseComponent
  delegate :action_formation?,
    :bilan_competences?,
    :validation_acquis_experience?,
    :apprentissage?,
    :obtention_via_unite_legale?,
    :specialites,
    to: :market_attribute_response

  def certified_text(boolean_value)
    if boolean_value
      t('form_fields.candidate.carif_oref.qualiopi.certified')
    else
      t('form_fields.candidate.carif_oref.qualiopi.not_certified')
    end
  end

  def specialites?
    specialites.present?
  end
end
