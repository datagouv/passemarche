# frozen_string_literal: true

module ApiResponses
  module QualibatResponses
    def qualibat_success_response(overrides: {})
      default_response = {
        data: {
          document_url: 'https://qualibat.example.com/certificat.pdf'
        }
      }

      default_response.deep_merge(overrides).to_json
    end

    def qualibat_unauthorized_response
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

    def qualibat_not_found_response
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

    def qualibat_invalid_json_response
      'not a json'
    end

    def qualibat_empty_response
      ''
    end

    def qualibat_response_without_data_key
      { foo: 'bar' }.to_json
    end
  end
end
