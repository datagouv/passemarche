class Insee::BuildResource < BuildResource
  protected

  def resource_attributes
    {
      siret:,
      category:,
      main_activity:,
      social_reason:,
      ess:
    }
  end

  private

  def siret
    json_body['siret']
  end

  def category
    json_body.dig('unite_legale', 'categorie_entreprise')
  end

  def main_activity
    json_body.dig('activite_principale', 'libelle')
  end

  def social_reason
    json_body.dig('unite_legale', 'personne_morale_attributs', 'raison_sociale')
  end

  def ess
    ess_value = json_body.dig('unite_legale', 'economie_sociale_solidaire')
    return nil if ess_value.nil?

    build_ess_radio_response(ess_value)
  end

  def build_ess_radio_response(ess_value)
    if ess_value == true
      { 'radio_choice' => 'yes', 'text' => I18n.t('api.insee.ess.is_ess') }
    else
      { 'radio_choice' => 'no' }
    end
  end
end
