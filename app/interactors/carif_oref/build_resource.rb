# frozen_string_literal: true

class CarifOref::BuildResource < BuildResource
  protected

  def resource_attributes
    {
      qualiopi: build_qualiopi_data,
      france_competence: build_france_competence_data
    }
  end

  private

  def build_qualiopi_data
    declaration = declarations_activites.first
    return nil if declaration.nil?

    {
      'numero_de_declaration' => declaration['numero_de_declaration'],
      'actif' => declaration['actif'],
      'date_derniere_declaration' => declaration['date_derniere_declaration'],
      'certification_qualiopi' => declaration['certification_qualiopi'],
      'specialites' => extract_specialites(declaration['specialites'])
    }
  end

  def build_france_competence_data
    habilitations = json_body['habilitations_france_competence'] || []
    return nil if habilitations.empty?

    { 'habilitations' => habilitations }
  end

  def declarations_activites
    json_body['declarations_activites_etablissement'] || []
  end

  def extract_specialites(specialites_hash)
    return [] if specialites_hash.nil?

    specialites_hash.values.map do |specialite|
      { 'code' => specialite['code'], 'libelle' => specialite['libelle'] }
    end
  end
end
