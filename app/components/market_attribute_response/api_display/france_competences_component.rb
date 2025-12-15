# frozen_string_literal: true

class MarketAttributeResponse::ApiDisplay::FranceCompetencesComponent < MarketAttributeResponse::ApiDisplay::BaseComponent
  delegate :habilitations, to: :market_attribute_response

  def multiple_habilitations?
    habilitations.size > 1
  end

  def habilitation_actif(habilitation)
    yes_no(habilitation['actif'])
  end

  def habilitation_date_actif(habilitation)
    format_date(habilitation['date_actif'])
  end

  def habilitation_date_fin_enregistrement(habilitation)
    format_date(habilitation['date_fin_enregistrement'])
  end

  def habilitation_pour_former(habilitation)
    yes_no(habilitation['habilitation_pour_former'])
  end

  def habilitation_pour_organiser_evaluation(habilitation)
    yes_no(habilitation['habilitation_pour_organiser_l_evaluation'])
  end

  def habilitation_sirets(habilitation)
    sirets = habilitation['sirets_organismes_certificateurs']
    return nil if sirets.blank?

    sirets.join(', ')
  end
end
