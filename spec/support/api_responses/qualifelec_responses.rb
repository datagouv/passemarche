# frozen_string_literal: true

module ApiResponses
  module QualifelecResponses
    def qualifelec_success_response(overrides: {})
      default_response = {
        data: [
          {
            data: {
              document_url: 'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_qualifelec_certificats/exemple-certificat-qualifelec-bac-a-sable-1.jpg',
              numero: 5430,
              rge: true,
              date_debut: '2019-01-01',
              date_fin: '2021-12-31'
            }
          },
          {
            data: {
              document_url: 'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_qualifelec_certificats/exemple-certificat-qualifelec-bac-a-sable-2.jpg',
              numero: 5431,
              rge: false,
              date_debut: '2020-01-01',
              date_fin: '2023-12-31'
            }
          }
        ]
      }

      default_response.deep_merge(overrides).to_json
    end

    def qualifelec_single_certificate_response
      {
        data: [
          {
            data: {
              document_url: 'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_qualifelec_certificats/exemple-certificat-qualifelec-bac-a-sable.jpg',
              numero: 5430,
              rge: true,
              date_debut: '2019-01-01',
              date_fin: '2021-12-31'
            }
          }
        ]
      }.to_json
    end

    def qualifelec_empty_response
      {
        data: []
      }.to_json
    end

    def qualifelec_unauthorized_response
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

    def qualifelec_not_found_response
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

    def qualifelec_invalid_json_response
      'not a json'
    end

    def qualifelec_response_without_data_key
      { foo: 'bar' }.to_json
    end

    def qualifelec_response_with_missing_document_urls
      {
        data: [
          {
            data: {
              document_url: 'https://example.com/cert1.jpg',
              numero: 1
            }
          },
          {
            data: {
              numero: 2
            }
          },
          {
            data: {
              document_url: 'https://example.com/cert3.jpg',
              numero: 3
            }
          }
        ]
      }.to_json
    end
  end
end
