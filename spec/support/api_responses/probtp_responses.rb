# frozen_string_literal: true

module ApiResponses
  module ProbtpResponses
    def probtp_attestation_success_response(siret: '41816609600069', overrides: {})
      default_response = {
        data: {
          document_url: "https://storage.entreprise.api.gouv.fr/siade/1569139162-#{siret}-attestation_probtp.pdf",
          expires_in: 7_889_238
        },
        links: {},
        meta: {}
      }

      default_response.deep_merge(overrides).to_json
    end

    def probtp_not_found_response
      {
        errors: [
          {
            code: '00404',
            title: 'Ressource non trouvée',
            detail: "L'établissement n'est pas enregistré au PRO BTP",
            source: {
              parameter: 'siret'
            },
            meta: {}
          }
        ]
      }.to_json
    end

    def probtp_invalid_siret_response
      {
        errors: [
          {
            code: '00422',
            title: 'Entité non traitable',
            detail: 'Le SIRET fourni n\'est pas valide',
            source: {
              parameter: 'siret'
            },
            meta: {}
          }
        ]
      }.to_json
    end

    def probtp_unauthorized_response
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

    def probtp_forbidden_response
      {
        errors: [
          {
            code: '00100',
            title: 'Privilèges insuffisants',
            detail: 'Votre token est valide mais vos privilèges sont insuffisants',
            source: {
              parameter: 'token'
            },
            meta: {}
          }
        ]
      }.to_json
    end

    def probtp_rate_limit_response
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

    def probtp_attestation_success_data(siret: '41816609600069', overrides: {})
      JSON.parse(probtp_attestation_success_response(siret:, overrides:))
    end

    def probtp_invalid_json_response
      'This is not valid JSON at all { malformed'
    end

    def probtp_empty_response
      ''
    end

    def probtp_response_without_data_key
      {
        links: {},
        meta: {}
      }.to_json
    end
  end
end
