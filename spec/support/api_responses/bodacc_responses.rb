# frozen_string_literal: true

module ApiResponses
  module BodaccResponses
    def bodacc_success_response(overrides: {})
      default_response = {
        nhits: 50,
        parameters: {
          dataset: 'annonces-commerciales',
          rows: 10,
          start: 0,
          facet: [],
          format: 'json',
          timezone: 'UTC'
        },
        records: [
          {
            datasetid: 'annonces-commerciales',
            recordid: 'c8f4d5e6b2a1c9d8e7f0a3b4c5d6e7f8',
            fields: {
              registre: 'SIREN',
              numero_immatriculation: '123456789',
              publicationavis: 'A',
              date_parution: '2024-01-15',
              cp: '75001',
              ville: 'PARIS',
              jugement: '{"nature": "clôture", "codeNature": "CL"}'
            },
            geometry: {
              type: 'Point',
              coordinates: [2.3522, 48.8566]
            },
            record_timestamp: '2024-01-15T10:30:00.000Z'
          }
        ],
        facet_groups: []
      }

      default_response.deep_merge(overrides).to_json
    end

    def bodacc_liquidation_response(siren: '123456789', overrides: {})
      default_response = {
        nhits: 1,
        parameters: {
          dataset: 'annonces-commerciales',
          rows: 10,
          start: 0,
          facet: [],
          format: 'json',
          timezone: 'UTC'
        },
        records: [
          {
            datasetid: 'annonces-commerciales',
            recordid: 'liquidation-record-id',
            fields: {
              registre: 'SIREN',
              numero_immatriculation: siren,
              publicationavis: 'A',
              date_parution: '2024-01-15',
              cp: '75001',
              ville: 'PARIS',
              jugement: '{"nature": "liquidation judiciaire", "codeNature": "LJ", "date": "2024-01-10", "tribunal": "Tribunal de Commerce de Paris"}'
            },
            geometry: {
              type: 'Point',
              coordinates: [2.3522, 48.8566]
            },
            record_timestamp: '2024-01-15T10:30:00.000Z'
          }
        ],
        facet_groups: []
      }

      default_response.deep_merge(overrides).to_json
    end

    def bodacc_dirigeant_response(siren: '123456789', overrides: {})
      default_response = {
        nhits: 1,
        parameters: {
          dataset: 'annonces-commerciales',
          rows: 10,
          start: 0,
          facet: [],
          format: 'json',
          timezone: 'UTC'
        },
        records: [
          {
            datasetid: 'annonces-commerciales',
            recordid: 'dirigeant-record-id',
            fields: {
              registre: 'SIREN',
              numero_immatriculation: siren,
              publicationavis: 'A',
              date_parution: '2024-01-15',
              cp: '75001',
              ville: 'PARIS',
              jugement: '{"nature": "faillite personnelle", "codeNature": "FP"}'
            },
            geometry: {
              type: 'Point',
              coordinates: [2.3522, 48.8566]
            },
            record_timestamp: '2024-01-15T10:30:00.000Z'
          }
        ],
        facet_groups: []
      }

      default_response.deep_merge(overrides).to_json
    end

    def bodacc_empty_response(overrides: {})
      default_response = {
        nhits: 0,
        parameters: {
          dataset: 'annonces-commerciales',
          rows: 10,
          start: 0,
          facet: [],
          format: 'json',
          timezone: 'UTC'
        },
        records: [],
        facet_groups: []
      }

      default_response.deep_merge(overrides).to_json
    end

    def bodacc_error_response(status: 500, message: 'Internal Server Error')
      {
        error: {
          status:,
          message:,
          code: 'BODACC_API_ERROR'
        }
      }.to_json
    end

    def bodacc_timeout_response
      bodacc_error_response(status: 408, message: 'Request Timeout')
    end

    def bodacc_not_found_response
      bodacc_error_response(status: 404, message: 'Dataset not found')
    end

    def bodacc_unauthorized_response
      bodacc_error_response(status: 401, message: 'Unauthorized access')
    end
  end
end
