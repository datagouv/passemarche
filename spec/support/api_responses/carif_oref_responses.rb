# frozen_string_literal: true

module ApiResponses
  module CarifOrefResponses
    def carif_oref_success_response(overrides: {})
      default_response = {
        data: {
          siret: '12000101100010',
          code_uai: '0123456A',
          unite_legale_avec_plusieurs_nda: false,
          declarations_activites_etablissement: [
            {
              numero_de_declaration: '11910843391',
              actif: true,
              date_derniere_declaration: '2021-01-30',
              date_debut_exercice: '2021-01-30',
              date_fin_exercice: '2021-01-30',
              certification_qualiopi: {
                action_formation: true,
                bilan_competences: true,
                validation_acquis_experience: false,
                apprentissage: true,
                obtention_via_unite_legale: true
              },
              specialites: {
                specialite_1: {
                  code: '313',
                  libelle: 'Finances, banque, assurances'
                },
                specialite_2: {
                  code: '326',
                  libelle: 'Informatique, traitement de l\'information, réseaux de transmission des données'
                },
                specialite_3: {
                  code: '327',
                  libelle: 'Langues'
                }
              }
            }
          ],
          habilitations_france_competence: [
            {
              code: 'RNCP10013',
              actif: true,
              date_actif: '2020-01-30',
              date_fin_enregistrement: '2030-01-30',
              date_decision: '2020-01-30',
              habilitation_pour_former: true,
              habilitation_pour_organiser_l_evaluation: true,
              sirets_organismes_certificateurs: ['12345678901234']
            },
            {
              code: 'RS5678',
              actif: true,
              date_actif: '2021-06-15',
              date_fin_enregistrement: '2031-06-15',
              date_decision: '2021-06-15',
              habilitation_pour_former: true,
              habilitation_pour_organiser_l_evaluation: false,
              sirets_organismes_certificateurs: ['98765432109876']
            }
          ]
        },
        links: {},
        meta: {}
      }

      default_response.deep_merge(overrides).to_json
    end

    def carif_oref_qualiopi_only_response
      {
        data: {
          siret: '12000101100010',
          declarations_activites_etablissement: [
            {
              numero_de_declaration: '11910843391',
              actif: true,
              certification_qualiopi: {
                action_formation: true,
                bilan_competences: false,
                validation_acquis_experience: false,
                apprentissage: false,
                obtention_via_unite_legale: true
              },
              specialites: {
                specialite_1: {
                  code: '313',
                  libelle: 'Finances, banque, assurances'
                }
              }
            }
          ],
          habilitations_france_competence: []
        },
        links: {},
        meta: {}
      }.to_json
    end

    def carif_oref_france_competences_only_response
      {
        data: {
          siret: '12000101100010',
          declarations_activites_etablissement: [],
          habilitations_france_competence: [
            {
              code: 'RNCP10013',
              actif: true,
              date_actif: '2020-01-30',
              date_fin_enregistrement: '2030-01-30',
              date_decision: '2020-01-30',
              habilitation_pour_former: true,
              habilitation_pour_organiser_l_evaluation: true,
              sirets_organismes_certificateurs: ['12345678901234']
            }
          ]
        },
        links: {},
        meta: {}
      }.to_json
    end

    def carif_oref_empty_response
      {
        data: {
          siret: '12000101100010',
          declarations_activites_etablissement: [],
          habilitations_france_competence: []
        },
        links: {},
        meta: {}
      }.to_json
    end

    def carif_oref_unauthorized_response
      {
        errors: [
          {
            status: 401,
            title: 'Unauthorized',
            detail: 'Invalid token'
          }
        ]
      }.to_json
    end

    def carif_oref_not_found_response
      {
        errors: [
          {
            status: 404,
            title: 'Not Found',
            detail: 'Etablissement not found'
          }
        ]
      }.to_json
    end

    def carif_oref_invalid_json_response
      'not a json'
    end
  end
end
