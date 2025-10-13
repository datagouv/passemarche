class Insee::BuildResource < BuildResource
  protected

  def resource_attributes
    {
      siret: json_body['siret'],
      category: json_body.dig('unite_legale', 'categorie_entreprise')
    }
  end
end
