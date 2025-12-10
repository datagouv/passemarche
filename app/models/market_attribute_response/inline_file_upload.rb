# frozen_string_literal: true

class MarketAttributeResponse::InlineFileUpload < MarketAttributeResponse::FileUpload
  # Inherits all behavior from FileUpload
  # Uses two-column layout in views via naming convention

  # Qualiopi metadata accessors
  def qualiopi_metadata?
    market_attribute&.api_name == 'carif_oref' &&
      market_attribute&.api_key == 'qualiopi' &&
      certification_qualiopi.present?
  end

  def numero_de_declaration
    value&.[]('numero_de_declaration')
  end

  def certification_qualiopi
    value&.[]('certification_qualiopi')
  end

  def specialites
    value&.[]('specialites') || []
  end

  # Certification flag helpers
  def action_formation?
    certification_qualiopi&.[]('action_formation') || false
  end

  def bilan_competences?
    certification_qualiopi&.[]('bilan_competences') || false
  end

  def validation_acquis_experience?
    certification_qualiopi&.[]('validation_acquis_experience') || false
  end

  def apprentissage?
    certification_qualiopi&.[]('apprentissage') || false
  end

  def obtention_via_unite_legale?
    certification_qualiopi&.[]('obtention_via_unite_legale') || false
  end
end
