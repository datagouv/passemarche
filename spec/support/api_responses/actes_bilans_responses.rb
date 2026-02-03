# frozen_string_literal: true

module ApiResponses
  module ActesBilansResponses
    def actes_bilans_success_response(overrides: {})
      default_response = {
        data: {
          actes: [],
          bilans: [
            {
              id: '65419234a1f7d1f2ba09bd8c',
              nom: 'Bilan 2022',
              date_depot: '2023-08-08',
              date_cloture: '2022-12-31',
              date_mise_a_jour: '2023-11-01',
              type_bilan: 'bilan complet',
              url: 'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_inpi_rne_actes_bilans/bilan_exemple_1.pdf'
            },
            {
              id: '65419234a1f7d1f2ba09bd8d',
              nom: 'Bilan 2021',
              date_depot: '2022-08-10',
              date_cloture: '2021-12-31',
              date_mise_a_jour: '2022-11-05',
              type_bilan: 'bilan complet',
              url: 'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_inpi_rne_actes_bilans/bilan_exemple_2.pdf'
            },
            {
              id: '65419234a1f7d1f2ba09bd8e',
              nom: 'Bilan 2020',
              date_depot: '2021-08-15',
              date_cloture: '2020-12-31',
              date_mise_a_jour: '2021-11-10',
              type_bilan: 'bilan simplifie',
              url: 'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_inpi_rne_actes_bilans/bilan_exemple_3.pdf'
            }
          ]
        }
      }

      default_response.deep_merge(overrides).to_json
    end

    def actes_bilans_single_bilan_response
      {
        data: {
          actes: [],
          bilans: [
            {
              id: '65419234a1f7d1f2ba09bd8c',
              nom: 'Bilan 2022',
              date_depot: '2023-08-08',
              date_cloture: '2022-12-31',
              date_mise_a_jour: '2023-11-01',
              type_bilan: 'bilan complet',
              url: 'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_inpi_rne_actes_bilans/bilan_exemple.pdf'
            }
          ]
        }
      }.to_json
    end

    def actes_bilans_empty_response
      {
        data: {
          actes: [],
          bilans: []
        }
      }.to_json
    end

    def actes_bilans_unauthorized_response
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

    def actes_bilans_not_found_response
      {
        errors: [
          {
            status: 404,
            title: 'Not Found',
            detail: 'Unite legale not found'
          }
        ]
      }.to_json
    end

    def actes_bilans_invalid_json_response
      'not a json'
    end

    def actes_bilans_response_without_data_key
      { foo: 'bar' }.to_json
    end

    def actes_bilans_response_with_missing_urls
      {
        data: {
          actes: [],
          bilans: [
            {
              id: '65419234a1f7d1f2ba09bd8c',
              nom: 'Bilan 2022',
              date_depot: '2023-08-08',
              url: 'https://example.com/bilan1.pdf'
            },
            {
              id: '65419234a1f7d1f2ba09bd8d',
              nom: 'Bilan 2021',
              date_depot: '2022-08-10'
            },
            {
              id: '65419234a1f7d1f2ba09bd8e',
              nom: 'Bilan 2020',
              date_depot: '2021-08-15',
              url: 'https://example.com/bilan3.pdf'
            }
          ]
        }
      }.to_json
    end
  end
end
