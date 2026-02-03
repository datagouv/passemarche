# frozen_string_literal: true

class MarketAttributeResponse::ApiDisplay::EssComponent < MarketAttributeResponse::ApiDisplay::BaseComponent
  def ess_status?
    value&.dig('radio_choice') == 'yes'
  end

  def status_label
    ess_status? ? t('form_fields.candidate.shared.yes') : t('form_fields.candidate.shared.no')
  end

  def display_label
    t('form_fields.candidate.fields.capacites_techniques_professionnelles_certificats_ess.display_label')
  end
end
