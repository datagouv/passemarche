# frozen_string_literal: true

module ApiResponses
  module BodaccResponses
    def bodacc_success_response(overrides: {})
      default_response = {
        total_count: 1,
        results: [
          {
            id: 'C202400123456',
            registre: ['123456789', '123 456 789'],
            publicationavis: 'A',
            dateparution: '2024-01-15',
            cp: '75001',
            ville: 'PARIS',
            jugement: '{"type": "initial", "famille": "Extrait de jugement", "nature": "Clôture pour extinction du passif", "date": "2024-01-10"}'
          }
        ]
      }

      default_response.deep_merge(overrides).to_json
    end

    def bodacc_liquidation_response(siren: '123456789', overrides: {})
      default_response = {
        total_count: 1,
        results: [
          {
            id: 'A202400123456',
            registre: [siren, siren.scan(/\d{3}/).join(' ')],
            publicationavis: 'A',
            dateparution: '2024-01-15',
            cp: '75001',
            ville: 'PARIS',
            jugement: '{"type": "initial", "famille": "Extrait de jugement", "nature": "Jugement prononçant la résolution du plan de redressement et la liquidation judiciaire", "date": "2024-01-10", "complementJugement": "Jugement prononçant la résolution du plan de redressement et la liquidation judiciaire - Tribunal de Commerce de Paris"}'
          }
        ]
      }

      default_response.deep_merge(overrides).to_json
    end

    def bodacc_dirigeant_response(siren: '123456789', overrides: {})
      default_response = {
        total_count: 1,
        results: [
          {
            id: 'A202400567890',
            registre: [siren, siren.scan(/\d{3}/).join(' ')],
            publicationavis: 'A',
            dateparution: '2024-01-15',
            cp: '75001',
            ville: 'PARIS',
            jugement: '{"type": "initial", "famille": "Extrait de jugement", "nature": "Jugement prononçant la faillite personnelle du dirigeant", "complementJugement": "Faillite personnelle du dirigeant avec interdiction de gérer toute entreprise commerciale"}'
          }
        ]
      }

      default_response.deep_merge(overrides).to_json
    end

    def bodacc_empty_response(overrides: {})
      default_response = {
        total_count: 0,
        results: []
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
