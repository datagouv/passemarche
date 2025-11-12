# frozen_string_literal: true

module ApiResponses
  module FntpResponses
    def fntp_attestation_success_response(siren: '418166096', overrides: {})
      default_response = {
        data: {
          document_url: "https://storage.entreprise.api.gouv.fr/siade/1569139162-#{siren}-carte_professionnelle.pdf",
          expires_in: 7_889_238
        },
        links: {},
        meta: {}
      }

      default_response.deep_merge(overrides).to_json
    end

    def fntp_not_found_response
      {
        errors: [
          {
            code: '00404',
            title: 'Ressource non trouvée',
            detail: "L'unité légale n'est pas enregistrée à la FNTP",
            source: {
              parameter: 'siren'
            },
            meta: {}
          }
        ]
      }.to_json
    end

    def fntp_invalid_siren_response
      {
        errors: [
          {
            code: '00422',
            title: 'Entité non traitable',
            detail: 'Le SIREN fourni n\'est pas valide',
            source: {
              parameter: 'siren'
            },
            meta: {}
          }
        ]
      }.to_json
    end

    def fntp_unauthorized_response
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

    def fntp_forbidden_response
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

    def fntp_rate_limit_response
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

    def fntp_attestation_success_data(siren: '418166096', overrides: {})
      JSON.parse(fntp_attestation_success_response(siren:, overrides:))
    end

    def fntp_invalid_json_response
      'This is not valid JSON at all { malformed'
    end

    def fntp_empty_response
      ''
    end

    def fntp_response_without_data_key
      {
        links: {},
        meta: {}
      }.to_json
    end
  end
end
