# frozen_string_literal: true

module ApiResponses
  module RneResponses
    def rne_extrait_success_response(siren: '418166096', overrides: {})
      default_response = {
        data: {
          document_url: "https://data.inpi.fr/export/companies?format=pdf&ids=[\"#{siren}\"]",
          identite_entreprise: {
            denomination: 'OCTO TECHNOLOGY',
            nom: nil,
            prenoms: nil,
            siren:,
            date_immatriculation_rne: '2018-03-15',
            date_debut_activite: '2018-04-01',
            detail_cessation: nil,
            dissolution: {
              date: nil,
              poursuite_activite: nil,
              avec_liquidation: nil
            },
            date_fin_personne: nil,
            date_cloture_exercice: '31-12',
            date_premiere_cloture_exercice: nil,
            nature_entreprise: 'COMMERCIALE',
            forme_juridique: {
              code: '5710',
              libelle: 'SAS, société par actions simplifiée'
            },
            associe_unique: false,
            activite_principales_objet_social: 'Conseil en systèmes et logiciels informatiques',
            code_APE: {
              code: '6202A',
              libelle: 'Conseil en systèmes et logiciels informatiques'
            },
            code_APRM: {
              code: nil,
              libelle: nil
            },
            capital_social: {
              montant: 50_000.0,
              devise: 'EUR'
            },
            adresse_siege_social: {
              voie: '50 AVENUE DES CHAMPS ÉLYSÉES',
              code_postal: '75008',
              commune: 'PARIS 8',
              pays: 'FRANCE',
              complement: nil
            }
          },
          dirigeants_et_associes: [
            {
              qualite: 'Président',
              nom: 'MARTIN',
              prenom: 'SOPHIE',
              date_naissance: '07-1985',
              commune_residence: 'PARIS'
            },
            {
              qualite: 'Directeur général',
              nom: 'DURAND',
              prenom: 'JEAN',
              date_naissance: '03-1978',
              commune_residence: 'LYON'
            }
          ],
          etablissements: []
        },
        meta: {
          date_derniere_mise_a_jour: 1_704_067_200
        },
        links: {}
      }

      default_response.deep_merge(overrides).to_json
    end

    def rne_extrait_entrepreneur_individuel_response(siren: '389839937')
      rne_extrait_success_response(
        siren:,
        overrides: {
          data: {
            identite_entreprise: {
              denomination: nil,
              nom: 'DUBOIS',
              prenoms: %w[MARIE CLAIRE],
              adresse_siege_social: {
                voie: '12 RUE DU COMMERCE',
                code_postal: '69001',
                commune: 'LYON 1ER ARRONDISSEMENT',
                pays: 'FRANCE',
                complement: 'Appartement 3'
              }
            },
            dirigeants_et_associes: []
          }
        }
      )
    end

    def rne_extrait_not_found_response
      {
        errors: [
          {
            code: '00404',
            title: 'Unité légale non trouvée',
            detail: "L'unité légale demandée n'existe pas",
            source: {
              parameter: 'siren'
            },
            meta: {}
          }
        ]
      }.to_json
    end

    def rne_unauthorized_response
      {
        errors: [
          {
            code: '00101',
            title: 'Interdit',
            detail: "Votre token n'est pas valide ou n'est pas renseigné",
            source: {
              parameter: 'token'
            },
            meta: {}
          }
        ]
      }.to_json
    end

    def rne_invalid_json_response
      'This is not valid JSON at all { malformed'
    end

    def rne_empty_response
      ''
    end

    def rne_response_without_data_key
      {
        meta: {
          date_derniere_mise_a_jour: 1_704_067_200
        }
      }.to_json
    end

    def rne_extrait_success_data(siren: '418166096', overrides: {})
      JSON.parse(rne_extrait_success_response(siren:, overrides:))
    end
  end
end
