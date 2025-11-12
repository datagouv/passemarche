# frozen_string_literal: true

module ApiResponses
  module RgeResponses
    def rge_success_response(overrides: {})
      default_response = {
        data: [
          {
            data: {
              url: 'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_ademe_certificats_rge/exemple-ademe-rge-certificat_qualibat.pdf',
              nom_certificat: 'Qualisol CESI',
              domaine: 'Fenêtres, volets, portes extérieures 2020',
              meta_domaine: 'anciens domaines avant 2021',
              qualification: {
                code: '32',
                nom: 'QualiPV Elec - Pose de générateur photovoltaïque raccordé au réseau (32)'
              },
              organisme: 'qualibat',
              date_attribution: '2020-12-24',
              date_expiration: '2025-08-01',
              meta: {
                internal_id: 'Q112379-8611M12D10-2017-03-23',
                updated_at: '2021-02-25',
                archived: false
              }
            },
            links: {},
            meta: {}
          },
          {
            data: {
              url: 'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_ademe_certificats_rge/exemple-ademe-rge-certificat_qualipv.pdf',
              nom_certificat: 'QualiPV Elec',
              domaine: 'Installation électrique 2021',
              meta_domaine: 'nouveaux domaines 2021',
              qualification: {
                code: '33',
                nom: 'QualiPV Bât - Pose de générateur photovoltaïque sur bâtiment (33)'
              },
              organisme: 'qualit_enr',
              date_attribution: '2021-01-15',
              date_expiration: '2026-01-15',
              meta: {
                internal_id: 'Q112379-PV-2021-01-15',
                updated_at: '2021-01-16',
                archived: false
              }
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

    def rge_success_single_certificate_response
      {
        data: [
          {
            data: {
              url: 'https://raw.githubusercontent.com/etalab/siade_staging_data/refs/heads/develop/payloads/api_entreprise_v3_ademe_certificats_rge/exemple-ademe-rge-certificat_qualibat.pdf',
              nom_certificat: 'Qualisol CESI',
              domaine: 'Fenêtres, volets, portes extérieures 2020',
              meta_domaine: 'anciens domaines avant 2021',
              qualification: {
                code: '32',
                nom: 'QualiPV Elec - Pose de générateur photovoltaïque raccordé au réseau (32)'
              },
              organisme: 'qualibat',
              date_attribution: '2020-12-24',
              date_expiration: '2025-08-01',
              meta: {
                internal_id: 'Q112379-8611M12D10-2017-03-23',
                updated_at: '2021-02-25',
                archived: false
              }
            },
            links: {},
            meta: {}
          }
        ],
        meta: {},
        links: {}
      }.to_json
    end

    def rge_empty_response
      {
        data: [],
        meta: {},
        links: {}
      }.to_json
    end

    def rge_unauthorized_response
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

    def rge_not_found_response
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

    def rge_invalid_json_response
      'not a json'
    end

    def rge_response_without_data_key
      { foo: 'bar' }.to_json
    end
  end
end
