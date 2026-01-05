# frozen_string_literal: true

module ApiResponses
  module InseeResponses
    def insee_etablissement_success_response(siret: '41816609600069', overrides: {})
      default_response = {
        data: {
          siret:,
          siege_social: true,
          etat_administratif: 'A',
          date_fermeture: nil,
          activite_principale: {
            code: '6202A',
            libelle: 'Conseil en systèmes et logiciels informatiques',
            nomenclature: 'NAFRev2'
          },
          tranche_effectif_salarie: {
            code: '21',
            intitule: '50 à 99 salariés',
            date_reference: '2022',
            de: 50,
            a: 99
          },
          status_diffusion: 'diffusible',
          diffusable_commercialement: true,
          enseigne: 'OCTO TECHNOLOGY',
          unite_legale: {
            siren: '418166096',
            rna: nil,
            siret_siege_social: '41816609600069',
            type: 'personne_morale',
            personne_morale_attributs: {
              raison_sociale: 'OCTO TECHNOLOGY',
              sigle: 'OCTO'
            },
            personne_physique_attributs: {
              pseudonyme: nil,
              prenom_usuel: nil,
              prenom_1: nil,
              prenom_2: nil,
              prenom_3: nil,
              prenom_4: nil,
              nom_usage: nil,
              nom_naissance: nil,
              sexe: nil
            },
            categorie_entreprise: 'PME',
            status_diffusion: 'diffusible'
          }
        },
        meta: {
          date_derniere_mise_a_jour: 1_704_067_200
        },
        links: {}
      }

      default_response.deep_merge(overrides).to_json
    end

    def insee_etablissement_not_found_response
      {
        errors: [
          {
            code: '00404',
            title: 'Établissement non trouvé',
            detail: "L'établissement demandé n'existe pas",
            source: {
              parameter: 'siret'
            },
            meta: {}
          }
        ]
      }.to_json
    end

    def insee_unauthorized_response
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

    # Error response for 403 Forbidden
    def insee_forbidden_response
      {
        errors: [
          {
            code: '00100',
            title: 'Privilèges insuffisants',
            detail: 'Votre token est valide mais vos privilèges sont insuffisants. Listez vos privilèges sur /v2/privileges',
            source: {
              parameter: 'token'
            },
            meta: {}
          }
        ]
      }.to_json
    end

    def insee_rate_limit_response
      {
        errors: [
          {
            code: '00429',
            title: 'Trop de requêtes',
            detail: 'Vous avez effectué trop de requêtes',
            source: {},
            meta: {}
          }
        ]
      }.to_json
    end

    def insee_etablissement_success_data(siret: '41816609600069', overrides: {})
      JSON.parse(insee_etablissement_success_response(siret:, overrides:))
    end

    def insee_invalid_json_response
      'This is not valid JSON at all { malformed'
    end

    def insee_empty_response
      ''
    end

    def insee_response_without_data_key
      {
        meta: {
          date_derniere_mise_a_jour: 1_704_067_200
        }
      }.to_json
    end

    def insee_response_with_ess_true(siret: '41816609600069')
      insee_etablissement_success_response(
        siret:,
        overrides: {
          data: {
            unite_legale: {
              economie_sociale_et_solidaire: true
            }
          }
        }
      )
    end

    def insee_response_with_ess_false(siret: '41816609600069')
      insee_etablissement_success_response(
        siret:,
        overrides: {
          data: {
            unite_legale: {
              economie_sociale_et_solidaire: false
            }
          }
        }
      )
    end

    def insee_response_with_ess_null(siret: '41816609600069')
      insee_etablissement_success_response(
        siret:,
        overrides: {
          data: {
            unite_legale: {
              economie_sociale_et_solidaire: nil
            }
          }
        }
      )
    end
  end
end
