class Insee::BuildResource < BuildResource
  protected

  def resource_attributes
    {
      siret:,
      category:,
      main_activity:,
      social_reason:
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
end
