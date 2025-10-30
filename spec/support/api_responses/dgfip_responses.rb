# frozen_string_literal: true

module ApiResponses
  module DgfipResponses
    def dgfip_attestation_fiscale_success_response(siren: '418166096', overrides: {})
      default_response = {
        data: {
          document_url: "https://storage.entreprise.api.gouv.fr/siade/1569139162-#{siren}-attestation_fiscale_dgfip.pdf",
          document_url_expires_in: 86_400,
          date_delivrance_attestation: '2023-04-11',
          date_periode_analysee: '2023-03-31'
        },
        links: {},
        meta: {}
      }

      default_response.deep_merge(overrides).to_json
    end

    def dgfip_attestation_fiscale_not_found_response
      {
        errors: [
          {
            code: '00404',
            title: 'Unité légale non trouvée',
            detail: "L'unité légale demandée n'existe pas",
            source: {
              parameter: 'siren'
            },
            meta: {}
          }
        ]
      }.to_json
    end

    def dgfip_unauthorized_response
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

    def dgfip_forbidden_response
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

    def dgfip_rate_limit_response
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

    def dgfip_attestation_fiscale_success_data(siren: '418166096', overrides: {})
      JSON.parse(dgfip_attestation_fiscale_success_response(siren:, overrides:))
    end

    def dgfip_invalid_json_response
      'This is not valid JSON at all { malformed'
    end

    def dgfip_empty_response
      ''
    end

    def dgfip_response_without_data_key
      {
        links: {},
        meta: {}
      }.to_json
    end
  end
end
