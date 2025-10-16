# frozen_string_literal: true

class Rne::BuildResource < BuildResource
  protected

  def resource_attributes
    {
      first_name_last_name:,
      head_office_address:
    }
  end

  private

  def first_name_last_name
    # Extract first director's name (format: "Prenom Nom")
    first_director = json_body.dig('dirigeants_et_associes', 0)
    return nil unless first_director

    prenom = first_director['prenom']
    nom = first_director['nom']

    return nil unless prenom && nom

    "#{prenom} #{nom}"
  end

  def head_office_address
    # Format: "voie, complement, code_postal commune, pays"
    # complement is optional
    address = json_body.dig('identite_entreprise', 'adresse_siege_social')
    return nil unless address

    voie = address['voie']
    code_postal = address['code_postal']
    commune = address['commune']
    pays = address['pays']
    complement = address['complement']

    # Build address parts
    parts = [voie]
    parts << complement if complement.present?
    parts << "#{code_postal} #{commune}"
    parts << pays

    parts.compact.join(', ')
  end
end
