# frozen_string_literal: true

module ApiResponses
  module UrssafResponses
    def urssaf_attestation_success_response(overrides: {})
      default_response = {
        data: {
          entity_status: 'ok',
          document_url: 'https://attestation-vigilance-urssaf.fr/TelechargementAttestation.aspx?ID=1569139162&B99824D9C764AAE19A862A0AF',
          document_url_expires_in: 3600
        },
        links: {},
        meta: {
          api_version: '4.0.0'
        }
      }

      default_response.deep_merge(overrides)
    end

    def urssaf_attestation_refusal_response(overrides: {})
      default_response = {
        data: {
          entity_status: 'refus_de_delivrance'
        },
        links: {},
        meta: {
          api_version: '4.0.0'
        }
      }

      default_response.deep_merge(overrides)
    end

    def urssaf_attestation_error_response(overrides: {})
      default_response = {
        errors: [
          {
            code: '01000',
            title: 'Entité non trouvée',
            detail: "L'entité demandée n'a pas pu être trouvée.",
            status: 404,
            source: {
              parameter: 'siren',
              example: '418166096'
            }
          }
        ],
        meta: {
          api_version: '4.0.0'
        }
      }

      default_response.deep_merge(overrides)
    end
  end
end
