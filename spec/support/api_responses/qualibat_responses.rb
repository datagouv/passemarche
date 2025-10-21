module ApiResponses
  module QualibatResponses
    def qualibat_success_response(siret: '12345678901234', overrides: {})
      {
        'data' => {
          'document_url' => 'https://qualibat.example.com/certificat.pdf'
          }
        }.merge(overrides)
      }.to_json
    end

    def qualibat_invalid_json_response
      'not a json'
    end

    def qualibat_empty_response
      ''
    end

    def qualibat_response_without_data_key
      { 'foo' => 'bar' }.to_json
    end
  end
end
