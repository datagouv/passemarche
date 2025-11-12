# frozen_string_literal: true

module ApiResponses
  module OpqibiResponses
    def opqibi_success_response(overrides: {})
      default_response = {
        data: {
          numero_certificat: 'string',
          url: 'https://www.opqibi.com/fiche/1777',
          date_delivrance_certificat: '2021-01-28',
          duree_validite_certificat: 'valable un an',
          assurances: 'ALLIANZ - XL INSURANCE',
          qualifications: [
            {
              nom: 'Etude thermique réglementaire "maison individuelle"',
              code_qualification: '1331',
              definition: 'Cette qualification correspond à la réalisation des calculs thermiques réglementaires pour les constructions neuves.',
              rge: false
            }
          ],
          date_validite_qualifications: '2025-02-21',
          qualifications_probatoires: [],
          date_validite_qualifications_probatoires: '2025-02-21'
        },
        links: {},
        meta: {}
      }

      default_response.deep_merge(overrides).to_json
    end

    def opqibi_unauthorized_response
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

    def opqibi_not_found_response
      {
        errors: [
          {
            status: 404,
            title: 'Not Found',
            detail: 'Unité légale not found'
          }
        ]
      }.to_json
    end

    def opqibi_invalid_json_response
      'not a json'
    end

    def opqibi_empty_response
      ''
    end

    def opqibi_response_without_data_key
      { foo: 'bar' }.to_json
    end
  end
end
