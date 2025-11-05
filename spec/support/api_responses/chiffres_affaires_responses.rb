# frozen_string_literal: true

module ApiResponses
  module ChiffresAffairesResponses
    def chiffres_affaires_success_response(_siret: '41816609600069', overrides: {})
      default_response = {
        data: [
          {
            data: {
              chiffre_affaires: 500_000,
              date_fin_exercice: '2023-12-31'
            },
            links: {},
            meta: {}
          },
          {
            data: {
              chiffre_affaires: 450_000,
              date_fin_exercice: '2022-12-31'
            },
            links: {},
            meta: {}
          },
          {
            data: {
              chiffre_affaires: 400_000,
              date_fin_exercice: '2021-12-31'
            },
            links: {},
            meta: {}
          }
        ],
        meta: {},
        links: {}
      }

      default_response.deep_merge(overrides).to_json
    end

    def chiffres_affaires_not_found_response
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

    def chiffres_affaires_unauthorized_response
      {
        errors: [
          {
            code: '00401',
            title: 'Token invalide',
            detail: 'Le token fourni est invalide',
            source: {
              parameter: 'token'
            },
            meta: {}
          }
        ]
      }.to_json
    end

    def chiffres_affaires_empty_response
      {
        data: [],
        meta: {},
        links: {}
      }.to_json
    end

    def chiffres_affaires_invalid_json_response
      'not a json'
    end
  end
end
